# Venice

[![Swift][swift-badge]][swift-url]
[![License][mit-badge]][mit-url]
[![Slack][slack-badge]][slack-url]
[![Travis][travis-badge]][travis-url]

**Venice** provides [CSP](https://en.wikipedia.org/wiki/Communicating_sequential_processes) for **Swift 3.0**.

## Features

- [x] Coroutines
- [x] Channels
- [x] Fallible Channels
- [x] Receive-only Channels
- [x] Send-only Channels
- [x] Channel Iteration
- [x] Select
- [x] Timers
- [x] Tickers
- [x] File Descriptor Polling

**Venice** wraps a fork of the C library [libmill](https://github.com/sustrik/libmill).

## Installation

- Add `Venice` to your `Package.swift`

```swift
import PackageDescription

let package = Package(
    dependencies: [
        .Package(url: "https://github.com/Zewo/Venice.git", majorVersion: 0, minor: 14)
    ]
)
```

## Usage

### `co`

`co` starts execution of a coroutine

```swift
func doSomething() {
    print("did something")
}

// regular call
doSomething()

// coroutine call
co(doSomething())

// coroutine closure
co {
    print("did something else")
}
```

### `nap` and `wake`

`nap` stops the execution **for** the given amount of time, while `wake` stops the execution **until** some moment.

```swift
co {
    // sleep for one second
    nap(for: 1.second)
    print("yawn")
}

// stop for two seconds so the program
// doesn't terminate before the print
let deadline = 2.seconds.fromNow()
wake(at: deadline)
```

Always use `nap` if you're setting up the time yourself. Use `wake` only if you got `deadline` from somewhere else.

### `after`

`after` runs the coroutine after the specified duration.

```swift
after(1.second) {
    print("yoo")
}

// same as

co {
    nap(for: 1.second)
    print("yoo")
}
```

### `every`

`every` runs the expression in a coroutine periodically. Call done() to leave the loop.

```swift
var count = 0
every(1.second) { done in
    print("yoo")
    count += 1
    if count == 3 {
        done()
    }
}

// same as

var count = 0
co {
    while true {
        nap(for: 1.second)
        print("yoo")
        count += 1
        if count == 3 { break }
    }
}
```

### `Channel<Element>`

Channels are typed and return optionals wrapping the value or nil if the channel is closed and doesn't have any values left in the buffer.

```swift
let messages = Channel<String>()
co(messages.send("ping"))
let message = messages.receive()!
print(message)

// buffered channels

let messages = Channel<String>(bufferSize: 2)

messages.send("buffered")
messages.send("channel")

print(messages.receive()!)
print(messages.receive()!)
```

### `ReceivingChannel<Element>` and `SendingChannel<Element>`

You can get a reference to a channel with receive or send only capabilities.

```swift
func receiveOnly(from channel: ReceivingChannel<String>) {
    // can only receive from channel
    let string = channel.receive()!
}

func sendOnly(on channel: SendingChannel<String>) {
    // can only send to channel
    channel.send("yo")
}

let channel = Channel<String>(bufferSize: 1)
receiveOnly(from: channel.receivingChannel)
sendOnly(to: channel.sendingChannel)
```

### `FallibleChannel<Type>`

Fallible channels accept values and errors as well.

```swift
struct Error: ErrorProtocol {}

let channel = FallibleChannel<String>(bufferSize: 2)

channel.send("yo")
channel.send(Error())

do {
    let yo = try channel.receive()
    try channel.receive() // will throw
} catch {
    print("error")
}

```

### `select`

Sometimes `select` can clash with the system libraries function with the same name `select`. To solve this you can call Venice's select with `Venice.select`or with the terser alias `sel`.

```swift
let channel = Channel<String>()
let fallibleChannel = FallibleChannel<String>()

select { when in
    when.receive(from: channel) { value in
        print("received \(value)")
    }
    when.receive(from: fallibleChannel) { result in
        result.success { value in
            print(value)
        }
        result.failure { error in
            print(error)
        }
    }
    when.send("value", to: channel) {
        print("sent value")
    }
    when.send("value", to: fallibleChannel) {
        print("sent value")
    }
    when.send(Error(), to: fallibleChannel) {
        print("threw error")
    }
    when.timeout(1.second.fromNow()) {
        print("timeout")
    }
    when.otherwise {
        print("default case")
    }
}
```

You can disable a channel selection by turning it to nil

```swift

var channelA: Channel<String>? = Channel<String>()
var channelB: Channel<String>? = Channel<String>()

if random(0...1) == 0 {
    channelA = nil
    print("disabled channel a")
} else {
    channelB = nil
    print("disabled channel b")
}

co { channelA?.send("a") }
co { channelB?.send("b") }

sel { when in
    when.receive(from: channelA) { value in
        print("received \(value) from channel a")
    }
    when.receive(from: channelB) { value in
        print("received \(value) from channel b")
    }
}
```

Another way to disable a channel selection is to simply put its case inside an if statement.

```swift
let channelA = Channel<String>()
let channelB = Channel<String>()

co(channelA.send("a"))
co(channelB.send("b"))

select { when in
    if random(0...1) == 0 {
        print("disabled channel b")
        when.receive(from: channelA) { value in
            print("received \(value) from channel a")
        }
    } else {
        print("disabled channel a")
        when.receive(from: channelB) { value in
            print("received \(value) from channel b")
        }
    }
}

```

### `forSelect`

A lot of times we need to wrap our select inside a while loop. To make it easier to work with this pattern we can use `forSelect`. `forSelect` will loop until you call `done()`.

```swift
func flipCoin(outcome: FallibleChannel<String>) {
    if random(0...1) == 0 {
        outcome.send("Success")
    } else {
        outcome.send(Error(description: "Something went wrong"))
    }
}

let outcome = FallibleChannel<String>()

co(flipCoin(outcome))

forSelect { when, done in
    when.receive(from: outcome) { result in
        result.success { value in
            print(value)
            done()
        }
        result.failure { error in
            print("\(error). Retrying...")
            co(flipCoin(results))
        }
    }
}
```

### `Timer`

`Timer` sends to its channel when it expires.

```swift
let timer = Timer(deadline: 2.second.fromNow())

co {
    timer.channel.receive()
    print("Timer expired")
}

if timer.stop() {
    print("Timer stopped")
}
```

### `Ticker`

`Ticker` sends current time to its channel periodically until stopped.

```swift
let ticker = Ticker(period: 500.milliseconds)

co {
    for time in ticker.channel {
        print("Tick at \(time)")
    }
}

after(2.seconds) {
    ticker.stop()
}
```

### `poll`

`poll` polls a file descriptor for reading or writing optionally timing out if the file descriptor is not ready before the given deadline.

```swift
do {
    // yields to other coroutines if fd not ready
    try poll(fileDescriptor, for: .writing, timingOut: 5.seconds.fromNow())
    // runs when fd is ready
    fileDescriptor.write(data)
} catch {
   // throws in case of timeout or polling error
}
```

# Examples

The examples 01-15 were taken from [gobyexample](http://gobyexample.com) and translated from Go to Swift using **Venice**.

## 01 - Coroutines

A *coroutine* is a lightweight thread of execution.

```swift
func f(from: String) {
    for i in 0 ..< 4 {
        print("\(from): \(i)")
        yield
    }
}
```

Suppose we have a function call `f(s)`. Here's how we'd call
that in the usual way, running it synchronously.

```
f(from: "direct")
```

To invoke this function in a coroutine, use `co(f(s))`. This new
coroutine will execute concurrently with the calling one.

```
co(f(from: "coroutine"))
```

You can also start a coroutine with a closure.

```
co {
    print("going")
}
```

Our two function calls are running asynchronously in separate
coroutines now, so execution falls through to here. We wait 1 second
before the program exits

```swift
nap(for: 1.second)
print("done")
```

When we run this program, we see the output of the blocking call
first, then the interleaved output of the two coroutines. This
interleaving reflects the coroutines being run concurrently by the
runtime.

### Output

```
direct: 0
direct: 1
direct: 2
direct: 3
coroutine: 0
going
coroutine: 1
coroutine: 2
coroutine: 3
done
```

## 02 - Channels

*Channels* are the pipes that connect concurrent
coroutines. You can send values into channels from one
coroutine and receive those values into another
coroutine.

Create a new channel with `Channel<Type>()`.
Channels are typed by the values they convey.

```swift
let messages = Channel<String>()
```

_Send_ a value into a channel using the `channel.send(value)`
syntax. Here we send `"ping"`  to the `messages`
channel we made above, from a new coroutine.

```swift
co(messages.send("ping"))
```

The `channel.receive()` syntax _receives_ a value from the
channel. Here we'll receive the `"ping"` message
we sent above and print it out.

```swift
let message = messages.receive()
print(message!)
```

When we run the program the "ping" message is successfully passed from
one coroutine to another via our channel. By default sends and receives block until both the sender and receiver are ready. This property allowed us to wait at the end of our program for the "ping" message without having to use any other synchronization.

Values received from channels are `Optional`s. If you try to get a value from a closed channel with no values left in the buffer, it'll return `nil`. If you are sure that there is a value wraped in the `Optional`, you can use the `!` operator, to force unwrap the optional.

### Output

```
ping
```

## 03 - Channel Buffering

By default channels are *unbuffered*, meaning that they
will only accept values (`channel.send(value)`) if there is a
corresponding receive (`let value = channel.receive()`) ready to receive the
value sent by the channel. _Buffered channels_ accept a limited
number of  values without a corresponding receiver for
those values.

Here we make a channel of strings buffering up to
2 values.

```swift
let messages = Channel<String>(bufferSize: 2)
```

Because this channel is buffered, we can send these
values into the channel without a corresponding
concurrent receive.

```swift
messages.send("buffered")
messages.send("channel")
```

Later we can receive these two values as usual.

```swift
print(messages.receive()!)
print(messages.receive()!)
```

### Output

```
buffered
channel
```

### 04 - Channel Synchronization

We can use channels to synchronize execution
across coroutines. Here's an example of using a
blocking receive to wait for a coroutine to finish.

This is the function we'll run in a coroutine. The
`done` channel will be used to notify another
coroutine that this function's work is done.

```swift
func worker(_ done: Channel<Void>) {
    print("working...")
    nap(for: 1.second)
    print("done")
    done.send() // Send to notify that we're done.
}
```

Start a worker coroutine, giving it the channel to
notify on.

```swift
let done = Channel<Void>(bufferSize: 1)
co(worker(done))
```

Block until we receive a notification from the
worker on the channel.

```swift
done.receive()
```

If you remove the `done.receive()` line from this program, the program would
exit before the worker even started.

### Output

```
working...
done
```

## 05 - Channel Directions

When using channels as function parameters, you can
specify if a channel is meant to only send or receive
values. This specificity increases the type-safety of
the program.

This `ping` function only accepts a channel that receives
values. It would be a compile-time error to try to
receive values from this channel.

```swift
func ping(message: String, to pingChannel: SendingChannel<String>) {
    pingChannel.send(message)
}
```

The `pong` function accepts one channel that only sends values
(`pings`) and a second that only receives values (`pongs`).

```swift
func pong(from pingChannel: ReceivingChannel<String>, to pongChannel: SendingChannel<String>) {
    let message = pingChannel.receive()!
    pongChannel.send(message)
}

let pings = Channel<String>(bufferSize: 1)
let pongs = Channel<String>(bufferSize: 1)

ping(message: "passed message", to: pings.sendingChannel)
pong(from: pings.receivingChannel, to: pongs.sendingChannel)

print(pongs.receive()!)
```

### Output

```
passed message
```

## 06 - Select

_Select_ lets you wait on multiple channel
operations. Combining coroutines and channels with
select is an extremely powerful feature.

For our example we'll select across two channels.

```swift
let channel1 = Channel<String>()
let channel2 = Channel<String>()
```

Each channel will receive a value after some amount
of time, to simulate e.g. blocking RPC operations
executing in concurrent coroutines.

```swift
after(1.second) {
    channel1.send("one")
}

after(2.seconds) {
    channel2.send("two")
}
```

We'll use `select` to await both of these values
simultaneously, printing each one as it arrives.

```swift
for _ in 0 ..< 2 {
    select { when in
        when.receive(from: channel1) { message1 in
            print("received \(message1)")
        }
        when.receive(from: channel2) { message2 in
            print("received \(message2)")
        }
    }
}
```

We receive the values `"one"` and then `"two"` as expected.
Note that the total execution time is only ~2 seconds since
both the 1 and 2 second `nap`s execute concurrently.

### Output

```
received one
received two
```

## 07 - Timeouts

_Timeouts_ are important for programs that connect to
external resources or that otherwise need to bound
execution time. Implementing timeouts is easy and
elegant thanks to channels and `select`.

For our example, suppose we're executing an external
call that returns its result on a channel `channel1`
after 2s.

```swift
let channel1 = Channel<String>(bufferSize: 1)

after(2.seconds) {
    channel1.send("result 1")
}
```

Here's the `select` implementing a timeout.
`received(resultFrom: channel1)` awaits the result and `timeout(1.second.fromNow())`
awaits a value to be sent after the timeout of
1s. Since `select` proceeds with the first
receive that's ready, we'll take the timeout case
if the operation takes more than the allowed 1s.

```swift
select { when in
    when.receive(from: channel1) { result in
        print(result)
    }
    when.timeout(1.second.fromNow()) {
        print("timeout 1")
    }
}
```

If we allow a longer timeout of 3s, then the receive
from `channel2` will succeed and we'll print the result.

```swift
let channel2 = Channel<String>(bufferSize: 1)

after(2.seconds) {
    channel2.send("result 2")
}

select { when in
    when.receive(from: channel2) { result in
        print(result)
    }
    when.timeout(3.seconds.fromNow()) {
        print("timeout 2")
    }
}
```

Running this program shows the first operation timing out and the second succeeding.

Using this select timeout pattern requires communicating results over channels. This is a
good idea in general because other important features are based on channels and select.
We’ll look at two examples of this next: timers and tickers.

### Output

```
timeout 1
result 2
```

## 08 - Non-Blocking Channel Operations

Basic sends and receives on channels are blocking.
However, we can use `select` with a `otherwise` clause to
implement _non-blocking_ sends, receives, and even
non-blocking multi-way `select`s.

```swift
let messages = Channel<String>()
let signals = Channel<Bool>()
```

Here's a non-blocking receive. If a value is
available on `messages` then `select` will take
the `received(valueFrom: messages)` case with that value. If not
it will immediately take the `otherwise` case.

```swift
select { when in
    when.receive(from: messages) { message in
        print("received message \(message)")
    }
    when.otherwise {
        print("no message received")
    }
}
```

A non-blocking send works similarly.

```swift
let message = "hi"

select { when in
    when.send(message, to: messages) {
        print("sent message \(message)")
    }
    when.otherwise {
        print("no message sent")
    }
}
```

We can use multiple cases above the `otherwise`
clause to implement a multi-way non-blocking
select. Here we attempt non-blocking receives
on both `messages` and `signals`.

```swift
select { when in
    when.receive(from: messages) { message in
        print("received message \(message)")
    }
    when.receive(from: signals) { signal in
        print("received signal \(signal)")
    }
    when.otherwise {
        print("no activity")
    }
}
```

### Output

```
no message received
no message sent
no activity
```

## 09 - Closing Channels

_Closing_ a channel indicates that no more values
can be sent to it. This can be useful to communicate
completion to the channel's receivers.

In this example we'll use a `jobs` channel to
communicate work to be done to a worker coroutine. When we have no more jobs for
the worker we'll `close` the `jobs` channel.

```swift
let jobs = Channel<Int>(bufferSize: 5)
let done = Channel<Void>()
```

Here's the worker coroutine. It repeatedly receives
from `jobs` with `j = jobs.receive()`. The return value
will be `nil` if `jobs` has been `close`d and all
values in the channel have already been received.
We use this to notify on `done` when we've worked
all our jobs.

```swift
co {
    while true {
        if let job = jobs.receive() {
            print("received job \(job)")
        } else {
            print("received all jobs")
            done.send()
            return
        }
    }
}
```

This sends 3 jobs to the worker over the `jobs`
channel, then closes it.

```swift
for job in 1...3 {
    print("sent job \(job)")
    jobs.send(job)
}

jobs.close()
print("sent all jobs")
```

We await the worker using the synchronization approach
we saw earlier.

```swift
done.receive()
```

The idea of closed channels leads naturally to our next example: iterating over channels.

### Output

```
sent job 1
received job 1
sent job 2
received job 2
sent job 3
received job 3
sent all jobs
received job 3
received all jobs
```

## 10 - Iterating Over Channels

We can use `for in` to iterate over
values received from a channel.
We'll iterate over 2 values in the `queue` channel.

```swift
let queue =  Channel<String>(bufferSize: 2)

queue.send("one")
queue.send("two")
queue.close()
```

This `for in` loop iterates over each element as it's
received from `queue`. Because we `close`d the
channel above, the iteration terminates after
receiving the 2 elements. If we didn't `close` it
we'd block on a 3rd receive in the loop.

```swift
for element in queue {
    print(element)
}
```

This example also showed that it’s possible to close a non-empty channel but still have the
remaining values be received.

### Output

```
one
two
```

## 11 - Timers

We often want to execute code at some point in the
future, or repeatedly at some interval. _Timer_ and
_ticker_ features make both of these tasks
easy. We'll look first at timers and then
at tickers.

Timers represent a single event in the future. You
tell the timer how long you want to wait, and it
provides a channel that will be notified at that
time. This timer will wait 2 seconds.

```swift
let timer1 = Timer(deadline: 2.seconds.fromNow())
```

The `timer1.channel.receive()` blocks on the timer's channel
until it sends a value indicating that the timer
expired.

```swift
timer1.channel.receive()
print("Timer 1 expired")
```

If you just wanted to wait, you could have used
`nap`. One reason a timer may be useful is
that you can cancel the timer before it expires.
Here's an example of that.

```swift
let timer2 = Timer(deadline: 1.second.fromNow())

co {
    timer2.channel.receive()
    print("Timer 2 expired")
}

if timer2.stop() {
    print("Timer 2 stopped")
}
```

The first timer will expire ~2s after we start the program, but the second should be stopped
before it has a chance to expire.

### Output

```
Timer 1 expired
Timer 2 stopped
```

## 12 - Tickers

Timers are for when you want to do
something once in the future - _tickers_ are for when
you want to do something repeatedly at regular
intervals. Here's an example of a ticker that ticks
periodically until we stop it.

Tickers use a similar mechanism to timers: a
channel that is sent values. Here we'll use the
`iterator` builtin on the channel to iterate over
the values as they arrive every 500ms.

```swift
let ticker = Ticker(period: 500.milliseconds)

co {
    for time in ticker.channel {
        print("Tick at \(time)")
    }
}
```

Tickers can be stopped like timers. Once a ticker
is stopped it won't receive any more values on its
channel. We'll stop ours after 1600ms.

```swift
nap(for: 1600.milliseconds)
ticker.stop()
print("Ticker stopped")
```

When we run this program the ticker should tick 3 times before we stop it.

### Output

```
Tick at 37024098
Tick at 37024599
Tick at 37025105
Ticker stopped
```

## 13 - Worker Pools

In this example we'll look at how to implement
a _worker pool_ using coroutines and channels.

Here's the worker, of which we'll run several
concurrent instances. These workers will receive
work on the `jobs` channel and send the corresponding
results on `results`. We'll sleep a second per job to
simulate an expensive task.

```swift
func worker(_ id: Int, jobs: Channel<Int>, results: Channel<Int>) {
    for job in jobs {
        print("worker \(id) processing job \(job)")
        nap(for: 1.second)
        results.send(job * 2)
    }
}
```

In order to use our pool of workers we need to send
them work and collect their results. We make 2
channels for this.

```swift
let jobs = Channel<Int>(bufferSize: 100)
let results = Channel<Int>(bufferSize: 100)
```

This starts up 3 workers, initially blocked
because there are no jobs yet.

```swift
for workerId in 1...3 {
    co(worker(workerId, jobs: jobs, results: results))
}
```

Here we send 9 `jobs` and then `close` that
channel to indicate that's all the work we have.

```swift
for job in 1...9 {
    jobs.send(job)
}

jobs.close()
```

Finally we collect all the results of the work.

```swift
for _ in 1...9 {
    results.receive()
}
```

Our running program shows the 9 jobs being executed by various workers. The program only
takes about 3 seconds despite doing about 9 seconds of total work because there are 3
workers operating concurrently.

### Output

```
worker 1 processing job 1
worker 2 processing job 2
worker 3 processing job 3
worker 1 processing job 4
worker 2 processing job 5
worker 3 processing job 6
worker 1 processing job 7
worker 2 processing job 8
worker 3 processing job 9
```

## 14 - Rate Limiting

_[Rate limiting](http://en.wikipedia.org/wiki/Rate_limiting)_
is an important mechanism for controlling resource
utilization and maintaining quality of service. Venice
elegantly supports rate limiting with coroutines,
channels, and tickers.

First we'll look at basic rate limiting. Suppose
we want to limit our handling of incoming requests.
We'll serve these requests off a channel of the
same name.

```swift
import C7  // now()
import Venice

var requests = Channel<Int>(bufferSize: 5)

for request in 1...5 {
    requests.send(request)
}

requests.close()
```

This `limiter` channel will receive a value
every 200 milliseconds. This is the regulator in
our rate limiting scheme.

```swift
let limiter = Ticker(period: 200.milliseconds)
```

By blocking on a receive from the `limiter` channel
before serving each request, we limit ourselves to
1 request every 200 milliseconds.

```swift
for request in requests {
    limiter.channel.receive()
    print("request \(request) \(now())")
}

print("")
```

We may want to allow short bursts of requests in
our rate limiting scheme while preserving the
overall rate limit. We can accomplish this by
buffering our limiter channel. This `burstyLimiter`
channel will allow bursts of up to 3 events.

```swift
let burstyLimiter = Channel<Double>(bufferSize: 3)
```

Fill up the channel to represent allowed bursting.

```swift
for _ in 0 ..< 3 {
    burstyLimiter.send(now())
}
```

Every 200 milliseconds we'll try to add a new
value to `burstyLimiter`, up to its limit of 3.

```swift
co {
    for time in Ticker(period: 200.milliseconds).channel {
        burstyLimiter.send(time)
    }
}
```

Now simulate 5 more incoming requests. The first
3 of these will benefit from the burst capability
of `burstyLimiter`.

```swift
let burstyRequests = Channel<Int>(bufferSize: 5)

for request in 1... 5 {
    burstyRequests.send(request)
}

burstyRequests.close()

for request in burstyRequests {
    _ = burstyLimiter.receive()!
    print("request \(request) \(now())")
}
```

Running our program we see the first batch of requests handled once every ~200 milliseconds
as desired.

For the second batch of requests we serve the first 3 immediately because of the burstable
rate limiting, then serve the remaining 2 with ~200ms delays each.

### Output

```
request 1 115342.499394391    |
request 2 115342.700038433    | received
request 3 115342.906077737    | each
request 4 115343.109621681    | 200msec
request 5 115343.314829288    |

request 1 115343.315044764    | burst
request 2 115343.315077373    |
request 3 115343.315102472    |
request 4 115343.519245856    <- 200msec later
request 5 115343.719813082    <- 200msec later
```

## 15 - Stateful Coroutines

In this example our state will be owned by a single
coroutine. This will guarantee that the data is never
corrupted with concurrent access. In order to read or
write that state, other coroutines will send messages
to the owning coroutine and receive corresponding
replies. These `ReadOperation` and `WriteOperation` `struct`s
encapsulate those requests and a way for the owning
coroutine to respond.

First you need a quick & dirty random function for this example

```swift
import C7
import Venice

#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif

func random (_ range: ClosedRange<Int>) -> Int {
    let (min, max) = (Int(range.lowerBound), Int(range.upperBound))
    #if os(Linux)
        return min + Int(random() % ((max - min) + 1))
    #else
        return min + Int(arc4random_uniform(UInt32(max - min + 1)))
    #endif
}
```

Let's start

```swift
struct ReadOperation {
    let key: Int
    let responses: Channel<Int>
}

struct WriteOperation {
    let key: Int
    let value: Int
    let responses: Channel<Void>
}
```

We'll count how many operations we perform.

```swift
var operations = 0
```

The `reads` and `writes` channels will be used by
other coroutines to issue read and write requests,
respectively.

```swift
let reads = Channel<ReadOperation>()
let writes = Channel<WriteOperation>()
```

Here is the coroutine that owns the `state`, which
is a dictionary private
to the stateful coroutine. This coroutine repeatedly
selects on the `reads` and `writes` channels,
responding to requests as they arrive. A response
is executed by first performing the requested
operation and then sending a value on the response
channel `responses` to indicate success (and the desired
value in the case of `reads`).

```swift
co {
    var state: [Int: Int] = [:]
    while true {
        select { when in
            when.receive(from: reads) { read in
                read.responses.send(state[read.key] ?? 0)
            }
            when.receive(from: writes) { write in
                state[write.key] = write.value
                write.responses.send()
            }
        }
    }
}
```

This starts 100 coroutines to issue reads to the
state-owning coroutine via the `reads` channel.
Each read requires constructing a `ReadOperation`, sending
it over the `reads` channel, and then receiving the
result over the provided `responses` channel.

```swift
for _ in 0 ..< 100 {
    co {
        while true {
            let read = ReadOperation(
                key: random(0...5),
                responses: Channel<Int>()
            )
            reads.send(read)
            read.responses.receive()
            operations += 1
        }
    }
}
```

We start 10 writes as well, using a similar
approach.

```swift
for _ in 0 ..< 10 {
    co {
        while true {
            let write = WriteOperation(
                key: random(0...5),
                value: random(0...100),
                responses: Channel<Void>()
            )
            writes.send(write)
            write.responses.receive()
            operations += 1
        }
    }
}
```

Let the coroutines work for a second.

```swift
nap(for: 1.second)
```

Finally, capture and report the `operations` count.

```swift
print("operations: \(operations)")
```

### Output

```
operations: 55798
```

## 16 - Chinese Whispers

```swift
func whisper(_ left: SendingChannel<Int>, _ right: ReceivingChannel<Int>) {
    left.send(right.receive()! + 1)
}

let n = 100000

let leftmost = Channel<Int>()
var right = leftmost
var left = leftmost

for _ in 0..<n {
    right = Channel<Int>()
    co(whisper(left.sendingChannel, right.receivingChannel))
    left = right
}

co {
    right.send(1)
}

print(leftmost.receive()!)
```

### Output

```
100001
```

(takes between 1 and 2 seconds)

## 17 - Ping Pong

```swift
final class Ball {
    var hits: Int = 0
}

func player(name: String, table: Channel<Ball>) {
    while true {
        let ball = table.receive()!
        ball.hits += 1
        print("\(name) \(ball.hits)")
        nap(for: 100.milliseconds)
        table.send(ball)
    }
}

let table = Channel<Ball>()

co(player(name: "ping", table: table))
co(player(name: "pong", table: table))

table.send(Ball())
nap(for: 1.second)
table.receive()
```

### Output

```
ping 1
pong 2
ping 3
pong 4
ping 5
pong 6
ping 7
pong 8
ping 9
pong 10
ping 11
```

## 18 - Fibonacci

```swift
func fibonacci(n: Int, channel: Channel<Int>) {
    var x = 0
    var y = 1
    for _ in 0..<n {
        channel.send(x)
        (x, y) = (y, x + y)
    }
    channel.close()
}

let fibonacciChannel = Channel<Int>(bufferSize: 10)

co(fibonacci(n: fibonacciChannel.bufferSize, channel: fibonacciChannel))

for n in fibonacciChannel {
    print(n)
}
```

### Output

```
0
1
1
2
3
5
8
13
21
34
```

## 19 - Bomb

```swift
let tick = Ticker(period: 100.milliseconds).channel
let boom = Timer(deadline: 500.milliseconds.fromNow()).channel

forSelect { when, done in
    when.receive(from: tick) { _ in
        print("tick")
    }
    when.receive(from: boom) { _ in
        print("BOOM!")
        done()
    }
    when.otherwise {
        print("    .")
        nap(for: 50.milliseconds)
    }
}
```

### Output

```
    .
    .
tick
    .
    .
tick
    .
    .
tick
    .
    .
tick
    .
BOOM!
```

## 20 - Tree

```swift
extension Collection where Index == Int {
    func shuffled() -> [Iterator.Element] {
        var list = Array(self)
        list.shuffle()
        return list
    }
}

extension MutableCollection where Index == Int {
    mutating func shuffle() {
        if count < 2 { return }

        for i in startIndex..<endIndex - 1 {
            let j = Int(arc4random_uniform(UInt32(endIndex - i))) + i  // could use random() from example 15
            guard i != j else { continue }
            swap(&self[i], &self[j])
        }
    }
}

final class Tree<T> {
    var left: Tree?
    var value: T
    var right: Tree?

    init(left: Tree?, value: T, right: Tree?) {
        self.left = left
        self.value = value
        self.right = right
    }
}
```

Traverses a tree depth-first,
sending each Value on a channel.

```swift
func walk<T>(_ tree: Tree<T>?, channel: Channel<T>) {
    if let tree = tree {
        walk(tree.left, channel: channel)
        channel.send(tree.value)
        walk(tree.right, channel: channel)
    }
}
```

Launches a walk in a new coroutine,
and returns a read-only channel of values.

```swift
func walker<T>(tree: Tree<T>?) -> ReceivingChannel<T> {
    let channel = Channel<T>()
    co {
        walk(tree, channel: channel)
        channel.close()
    }
    return channel.receivingChannel
}
```

Reads values from two walkers
that run simultaneously, and returns true
if tree1 and tree2 have the same contents.

```swift
func ==<T : Equatable>(tree1: Tree<T>, tree2: Tree<T>) -> Bool {
    let channel1 = walker(tree1)
    let channel2 = walker(tree2)
    while true {
        let value1 = channel1.receive()
        let value2 = channel2.receive()
        if value1 == nil || value2 == nil {
            return value1 == value2
        }
        if value1 != value2 {
            break
        }
    }
    return false
}
```

Returns a new, random binary tree
holding the values 1*k, 2*k, ..., n*k.

```swift
func newTree(n: Int, k: Int) -> Tree<Int> {
    var tree: Tree<Int>?
    for value in Array(1...n).shuffled() {
        tree = insert(value * k, in: tree)
    }
    return tree!
}
```

Inserts a value in the tree

```swift
func insert(_ value: Int, in tree: Tree<Int>?) -> Tree<Int> {
    if let tree = tree {
        if value < tree.value {
            tree.left = insert(value, in: tree.left)
            return tree
        } else {
            tree.right = insert(value, in: tree.right)
            return tree
        }
    } else {
        return Tree<Int>(left: nil, value: value, right: nil)
    }
}

let tree = newTree(n: 100, k: 1)

print("Same contents \(tree == newTree(n: 100, k: 1))")
print("Differing sizes \(tree == newTree(n: 99, k: 1))")
print("Differing values \(tree == newTree(n: 100, k: 2))")
print("Dissimilar \(tree == newTree(n: 101, k: 2))")
```

### Output

```
Same contents true
Differing sizes false
Differing values false
Dissimilar false
```

## 21 - Fake RSS Client

```swift
struct Item : Equatable {
    let domain: String
    let title: String
    let GUID: String
}

func ==(lhs: Item, rhs: Item) -> Bool {
    return lhs.GUID == rhs.GUID
}

struct FetchResponse {
    let items: [Item]
    let nextFetchTime: Int
}

protocol FetcherType {
    func fetch() -> ChannelResult<FetchResponse>
}

struct Fetcher : FetcherType {
    let domain: String

    func randomItems() -> [Item] {
        let items = [
            Item(domain: domain, title: "Swift 2.0", GUID: "1"),
            Item(domain: domain, title: "Strings in Swift 2", GUID: "2"),
            Item(domain: domain, title: "Swift-er SDK", GUID: "3"),
            Item(domain: domain, title: "Swift 2 Apps in the App Store", GUID: "4"),
            Item(domain: domain, title: "Literals in Playgrounds", GUID: "5"),
            Item(domain: domain, title: "Swift Open Source", GUID: "6")
        ]
        return [Item](items[0..<Int(arc4random_uniform(UInt32(items.count)))])
    }

    func fetch() -> ChannelResult<FetchResponse> {
        if arc4random_uniform(2) == 0 {
            let fetchResponse = FetchResponse(
                items: randomItems(),
                nextFetchTime: Int(300.milliseconds.fromNow())
            )
            return ChannelResult.value(fetchResponse)
        } else {
            struct LocalError : Error, CustomStringConvertible { let description: String }
            return ChannelResult.error(LocalError(description: "Network Error"))
        }
    }
}

protocol SubscriptionType {
    var updates: ReceivingChannel<Item> { get }
    func close() -> Error?
}

struct Subscription : SubscriptionType {
    let fetcher: FetcherType
    let items = Channel<Item>()
    let closing = Channel<Channel<Error?>>()

    init(fetcher: FetcherType) {
        self.fetcher = fetcher
        let copy = self
        co { copy.getUpdates() }
    }

    var updates: ReceivingChannel<Item> {
        return self.items.receivingChannel
    }

    func getUpdates() {
        let maxPendingItems = 10
        let fetchDone = Channel<ChannelResult<FetchResponse>>(bufferSize: 1)

        var lastError: Error?
        var pendingItems: [Item] = []
        var seenItems: [Item] = []
        var nextFetchTime = now()
        var fetching = false

        forSelect { when, done in
            when.receive(from: closing) { errorChannel in
                errorChannel.send(lastError)
                self.items.close()
                done()
            }

            if !fetching && pendingItems.count < maxPendingItems {
                when.timeout(nextFetchTime) {
                    fetching = true
                    co {
                        fetchDone.send(self.fetcher.fetch())
                    }
                }
            }

            when.receive(from: fetchDone) { fetchResult in
                fetching = false
                fetchResult.success { response in
                    for item in response.items {
                        if !seenItems.contains(item) {
                            pendingItems.append(item)
                            seenItems.append(item)
                        }
                    }
                    lastError = nil
                    nextFetchTime = Double(response.nextFetchTime)
                }
                fetchResult.failure { error in
                    lastError = error
                    nextFetchTime = 1.second.fromNow()
                }
            }

            if let item = pendingItems.first {
                when.send(item, to: items) {
                    pendingItems.removeFirst()
                }
            }
        }
    }

    func close() -> Error? {
        let errorChannel = Channel<Error?>()
        closing.send(errorChannel)
        return errorChannel.receive()!
    }
}


let fetcher = Fetcher(domain: "developer.apple.com/swift/blog/")
let subscription = Subscription(fetcher: fetcher)

after(5.seconds) {
    if let lastError = subscription.close() {
        print("Closed with last error: \(lastError)")
    } else {
        print("Closed with no last error")
    }
}

for item in subscription.updates {
    print("\(item.domain): \(item.title)")
}
```

### Output

```
developer.apple.com/swift/blog/: Swift 2.0
developer.apple.com/swift/blog/: Strings in Swift 2
developer.apple.com/swift/blog/: Swift-er SDK
developer.apple.com/swift/blog/: Swift 2 Apps in the App Store
Closed with last error: Network Error
```

## Support

If you need any help you can join our [Slack](http://slack.zewo.io) and go to the **#help** channel. Or you can create a Github [issue](https://github.com/Zewo/Zewo/issues/new) in our main repository. When stating your issue be sure to add enough details, specify what module is causing the problem and reproduction steps.

## Community

[![Slack][slack-image]][slack-url]

The entire Zewo code base is licensed under MIT. By contributing to Zewo you are contributing to an open and engaged community of brilliant Swift programmers. Join us on [Slack](http://slack.zewo.io) to get to know us!

## License

This project is released under the MIT license. See [LICENSE](LICENSE) for details.

[swift-badge]: https://img.shields.io/badge/Swift-3.0-orange.svg?style=flat
[swift-url]: https://swift.org
[mit-badge]: https://img.shields.io/badge/License-MIT-blue.svg?style=flat
[mit-url]: https://tldrlegal.com/license/mit-license
[slack-image]: http://s13.postimg.org/ybwy92ktf/Slack.png
[slack-badge]: https://zewo-slackin.herokuapp.com/badge.svg
[slack-url]: http://slack.zewo.io
[travis-badge]: https://travis-ci.org/Zewo/Venice.svg?branch=master
[travis-url]: https://travis-ci.org/Zewo/Venice
