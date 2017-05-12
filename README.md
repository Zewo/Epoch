<p align="center">
    <a href="http://zewo.io"><img src="https://raw.githubusercontent.com/Zewo/Zewo/master/Images/zewo.png" alt="Zewo"/></a>
</p>

<p align="center">
    <a href="https://swift.org"><img src="https://img.shields.io/badge/Swift-3.0-orange.svg?style=flat" alt="Swift" /></a>
    <a href="https://tldrlegal.com/license/mit-license"><img src="https://img.shields.io/badge/License-MIT-blue.svg?style=flat" alt="License" /></a>
    <a href="http://slack.zewo.io"><img src="https://zewo-slackin.herokuapp.com/badge.svg" alt="Slack" /></a>
    <a href="https://travis-ci.org/Zewo/Zewo"><img src="https://api.travis-ci.org/Zewo/Zewo.svg?branch=master" alt="Travis" /></a>
    <a href="https://codecov.io/gh/Zewo/Zewo"><img src="https://codecov.io/gh/Zewo/Zewo/branch/master/graph/badge.svg" alt="Codecov" /></a>
    <a href="https://codebeat.co/projects/github-com-zewo-zewo"><img src="https://codebeat.co/badges/d580cc1f-5bdb-494b-8391-d147c7a287a1" alt="Codebeat" /></a>
    <a href="#backers"><img src="https://opencollective.com/zewo/backers/badge.svg"></a>
    <a href="#sponsors"><img src="https://opencollective.com/zewo/sponsors/badge.svg"></a>
</p>

<p align="center">
	   <a href="#what-sets-zewo-apart">Why Zewo?</a>
    • <a href="#support">Support</a>
    • <a href="#community">Community</a>
    • <a href="https://github.com/Zewo/Zewo/blob/master/CONTRIBUTING.md">Contributing</a>
</p>

# Zewo

**Zewo** is a lightweight library for web applications in Swift.

## What sets Zewo apart?

Zewo is **not** a web framework. Zewo is a lightweight library for web applications in Swift. Most server-side Swift projects use Grand Central Dispatch (**GCD**) as the concurrency library of choice. The drawback of using GCD is that its APIs are **asynchronous**. With async code comes **callback hell** and we all know it, it's no fun.

Node.js is the best example of how callbacks can be frustrating. Express.js creator **TJ Holowaychuk** wrote a blog post about [Callback vs Coroutines](https://medium.com/@tjholowaychuk/callbacks-vs-coroutines-174f1fe66127#.3l3pf1xqf) in 2013 and one year later [left the Node.js community](https://medium.com/@tjholowaychuk/farewell-node-js-4ba9e7f3e52b#.okwqsltyx) in favor of Go. There were many reasons for that but one of the main reasons was the concurrency model. Sure we have futures and promises and functional reactive programming. They all mitigate the problem, but the async nature of the code will always be there.

At **Zewo** we use **coroutines**. Coroutines allow concurrency while maintaining **synchronous** APIs. We all learn how to program with synchronous code. We're used to reason about our code synchronously. Being able to use synchronous APIs makes the code much more readable and understandable. Coroutines are also **faster** than threads, because they're much lighter.

Our implementation of **coroutines** (which is based on [libdill](https://github.com/sustrik/libdill)) is **single-threaded**. This means that you don't have to worry about **locks** or **race conditions**. So your code is **safer** by default. To use all the CPU power available all you have to do is to replicate the work according to the number of logical CPUs available. As an example, this could mean running as many processes of your server as cores in your machine. **Rob Pike**, one of the creators of Go had a talk called [Concurrency is not Parallelism](https://www.youtube.com/watch?v=cN_DpYBzKso) that explains this concept **very** well. Go also has the philosophy:

```
Don't communicate by sharing memory. Share memory by communicating.
```

Like Go, instead of sharing memory and handling state we promote the use of [CSP](https://en.wikipedia.org/wiki/Communicating_sequential_processes)-style concurrency using channels. This pattern brings the abstractions used on the development of distributed systems closer to the way we're used to think about communication. It also aligns well with Swift's mindset of immutability and value types. All of these things contributes to a distinct experince on the server-side Swift.

With **Zewo** you get:

* Go-style concurrency
* Synchronous APIs
* Incredible performance
* Safer applications
* Scalable systems
* Cleaner code
* Proper error handling
* No callback hell
* No race conditions

## Test Coverage

[![Test Coverage][codecov-sunburst]][codecov-url]

The inner-most circle is the entire project, moving away from the center are folders then, finally, a single file. The size and color of each slice is represented by the number of statements and the coverage, respectively.

## Support

If you have **any** trouble create a Github [issue](https://github.com/Zewo/Zewo/issues/new) and we'll do everything we can to help you. When stating your issue be sure to add enough details and reproduction steps so we can help you faster. If you prefer you can join our [Slack](http://slack.zewo.io) and go to the **#help** channel too.

## Community

[![Slack][slack-image]][slack-url]

We have an amazing community of open and welcoming developers. Join us on [Slack](http://slack.zewo.io) to get to know us!

## Backers

Support us with a monthly donation and help us continue our activities. [[Become a backer](https://opencollective.com/zewo#backer)]

<a href="https://opencollective.com/zewo/backer/0/website" target="_blank"><img src="https://opencollective.com/zewo/backer/0/avatar.svg"></a>
<a href="https://opencollective.com/zewo/backer/1/website" target="_blank"><img src="https://opencollective.com/zewo/backer/1/avatar.svg"></a>
<a href="https://opencollective.com/zewo/backer/2/website" target="_blank"><img src="https://opencollective.com/zewo/backer/2/avatar.svg"></a>
<a href="https://opencollective.com/zewo/backer/3/website" target="_blank"><img src="https://opencollective.com/zewo/backer/3/avatar.svg"></a>
<a href="https://opencollective.com/zewo/backer/4/website" target="_blank"><img src="https://opencollective.com/zewo/backer/4/avatar.svg"></a>
<a href="https://opencollective.com/zewo/backer/5/website" target="_blank"><img src="https://opencollective.com/zewo/backer/5/avatar.svg"></a>
<a href="https://opencollective.com/zewo/backer/6/website" target="_blank"><img src="https://opencollective.com/zewo/backer/6/avatar.svg"></a>
<a href="https://opencollective.com/zewo/backer/7/website" target="_blank"><img src="https://opencollective.com/zewo/backer/7/avatar.svg"></a>
<a href="https://opencollective.com/zewo/backer/8/website" target="_blank"><img src="https://opencollective.com/zewo/backer/8/avatar.svg"></a>
<a href="https://opencollective.com/zewo/backer/9/website" target="_blank"><img src="https://opencollective.com/zewo/backer/9/avatar.svg"></a>
<a href="https://opencollective.com/zewo/backer/10/website" target="_blank"><img src="https://opencollective.com/zewo/backer/10/avatar.svg"></a>
<a href="https://opencollective.com/zewo/backer/11/website" target="_blank"><img src="https://opencollective.com/zewo/backer/11/avatar.svg"></a>
<a href="https://opencollective.com/zewo/backer/12/website" target="_blank"><img src="https://opencollective.com/zewo/backer/12/avatar.svg"></a>
<a href="https://opencollective.com/zewo/backer/13/website" target="_blank"><img src="https://opencollective.com/zewo/backer/13/avatar.svg"></a>
<a href="https://opencollective.com/zewo/backer/14/website" target="_blank"><img src="https://opencollective.com/zewo/backer/14/avatar.svg"></a>
<a href="https://opencollective.com/zewo/backer/15/website" target="_blank"><img src="https://opencollective.com/zewo/backer/15/avatar.svg"></a>
<a href="https://opencollective.com/zewo/backer/16/website" target="_blank"><img src="https://opencollective.com/zewo/backer/16/avatar.svg"></a>
<a href="https://opencollective.com/zewo/backer/17/website" target="_blank"><img src="https://opencollective.com/zewo/backer/17/avatar.svg"></a>
<a href="https://opencollective.com/zewo/backer/18/website" target="_blank"><img src="https://opencollective.com/zewo/backer/18/avatar.svg"></a>
<a href="https://opencollective.com/zewo/backer/19/website" target="_blank"><img src="https://opencollective.com/zewo/backer/19/avatar.svg"></a>
<a href="https://opencollective.com/zewo/backer/20/website" target="_blank"><img src="https://opencollective.com/zewo/backer/20/avatar.svg"></a>
<a href="https://opencollective.com/zewo/backer/21/website" target="_blank"><img src="https://opencollective.com/zewo/backer/21/avatar.svg"></a>
<a href="https://opencollective.com/zewo/backer/22/website" target="_blank"><img src="https://opencollective.com/zewo/backer/22/avatar.svg"></a>
<a href="https://opencollective.com/zewo/backer/23/website" target="_blank"><img src="https://opencollective.com/zewo/backer/23/avatar.svg"></a>
<a href="https://opencollective.com/zewo/backer/24/website" target="_blank"><img src="https://opencollective.com/zewo/backer/24/avatar.svg"></a>
<a href="https://opencollective.com/zewo/backer/25/website" target="_blank"><img src="https://opencollective.com/zewo/backer/25/avatar.svg"></a>
<a href="https://opencollective.com/zewo/backer/26/website" target="_blank"><img src="https://opencollective.com/zewo/backer/26/avatar.svg"></a>
<a href="https://opencollective.com/zewo/backer/27/website" target="_blank"><img src="https://opencollective.com/zewo/backer/27/avatar.svg"></a>
<a href="https://opencollective.com/zewo/backer/28/website" target="_blank"><img src="https://opencollective.com/zewo/backer/28/avatar.svg"></a>
<a href="https://opencollective.com/zewo/backer/29/website" target="_blank"><img src="https://opencollective.com/zewo/backer/29/avatar.svg"></a>

## Sponsors

Become a sponsor and get your logo on our website Zewo.io and on our README on Github with a link to your site. [[Become a sponsor](https://opencollective.com/zewo#sponsor)]

<a href="https://opencollective.com/zewo/sponsor/0/website" target="_blank"><img src="https://opencollective.com/zewo/sponsor/0/avatar.svg"></a>
<a href="https://opencollective.com/zewo/sponsor/1/website" target="_blank"><img src="https://opencollective.com/zewo/sponsor/1/avatar.svg"></a>
<a href="https://opencollective.com/zewo/sponsor/2/website" target="_blank"><img src="https://opencollective.com/zewo/sponsor/2/avatar.svg"></a>
<a href="https://opencollective.com/zewo/sponsor/3/website" target="_blank"><img src="https://opencollective.com/zewo/sponsor/3/avatar.svg"></a>
<a href="https://opencollective.com/zewo/sponsor/4/website" target="_blank"><img src="https://opencollective.com/zewo/sponsor/4/avatar.svg"></a>
<a href="https://opencollective.com/zewo/sponsor/5/website" target="_blank"><img src="https://opencollective.com/zewo/sponsor/5/avatar.svg"></a>
<a href="https://opencollective.com/zewo/sponsor/6/website" target="_blank"><img src="https://opencollective.com/zewo/sponsor/6/avatar.svg"></a>
<a href="https://opencollective.com/zewo/sponsor/7/website" target="_blank"><img src="https://opencollective.com/zewo/sponsor/7/avatar.svg"></a>
<a href="https://opencollective.com/zewo/sponsor/8/website" target="_blank"><img src="https://opencollective.com/zewo/sponsor/8/avatar.svg"></a>
<a href="https://opencollective.com/zewo/sponsor/9/website" target="_blank"><img src="https://opencollective.com/zewo/sponsor/9/avatar.svg"></a>
<a href="https://opencollective.com/zewo/sponsor/10/website" target="_blank"><img src="https://opencollective.com/zewo/sponsor/10/avatar.svg"></a>
<a href="https://opencollective.com/zewo/sponsor/11/website" target="_blank"><img src="https://opencollective.com/zewo/sponsor/11/avatar.svg"></a>
<a href="https://opencollective.com/zewo/sponsor/12/website" target="_blank"><img src="https://opencollective.com/zewo/sponsor/12/avatar.svg"></a>
<a href="https://opencollective.com/zewo/sponsor/13/website" target="_blank"><img src="https://opencollective.com/zewo/sponsor/13/avatar.svg"></a>
<a href="https://opencollective.com/zewo/sponsor/14/website" target="_blank"><img src="https://opencollective.com/zewo/sponsor/14/avatar.svg"></a>
<a href="https://opencollective.com/zewo/sponsor/15/website" target="_blank"><img src="https://opencollective.com/zewo/sponsor/15/avatar.svg"></a>
<a href="https://opencollective.com/zewo/sponsor/16/website" target="_blank"><img src="https://opencollective.com/zewo/sponsor/16/avatar.svg"></a>
<a href="https://opencollective.com/zewo/sponsor/17/website" target="_blank"><img src="https://opencollective.com/zewo/sponsor/17/avatar.svg"></a>
<a href="https://opencollective.com/zewo/sponsor/18/website" target="_blank"><img src="https://opencollective.com/zewo/sponsor/18/avatar.svg"></a>
<a href="https://opencollective.com/zewo/sponsor/19/website" target="_blank"><img src="https://opencollective.com/zewo/sponsor/19/avatar.svg"></a>
<a href="https://opencollective.com/zewo/sponsor/20/website" target="_blank"><img src="https://opencollective.com/zewo/sponsor/20/avatar.svg"></a>
<a href="https://opencollective.com/zewo/sponsor/21/website" target="_blank"><img src="https://opencollective.com/zewo/sponsor/21/avatar.svg"></a>
<a href="https://opencollective.com/zewo/sponsor/22/website" target="_blank"><img src="https://opencollective.com/zewo/sponsor/22/avatar.svg"></a>
<a href="https://opencollective.com/zewo/sponsor/23/website" target="_blank"><img src="https://opencollective.com/zewo/sponsor/23/avatar.svg"></a>
<a href="https://opencollective.com/zewo/sponsor/24/website" target="_blank"><img src="https://opencollective.com/zewo/sponsor/24/avatar.svg"></a>
<a href="https://opencollective.com/zewo/sponsor/25/website" target="_blank"><img src="https://opencollective.com/zewo/sponsor/25/avatar.svg"></a>
<a href="https://opencollective.com/zewo/sponsor/26/website" target="_blank"><img src="https://opencollective.com/zewo/sponsor/26/avatar.svg"></a>
<a href="https://opencollective.com/zewo/sponsor/27/website" target="_blank"><img src="https://opencollective.com/zewo/sponsor/27/avatar.svg"></a>
<a href="https://opencollective.com/zewo/sponsor/28/website" target="_blank"><img src="https://opencollective.com/zewo/sponsor/28/avatar.svg"></a>
<a href="https://opencollective.com/zewo/sponsor/29/website" target="_blank"><img src="https://opencollective.com/zewo/sponsor/29/avatar.svg"></a>

## License

All **Zewo** modules are released under the MIT license. See [LICENSE](LICENSE) for details.

[slack-image]: http://s13.postimg.org/ybwy92ktf/Slack.png
[slack-url]: http://slack.zewo.io
[codecov-url]: https://codecov.io/gh/Zewo/Zewo
[codecov-sunburst]: https://codecov.io/gh/Zewo/Zewo/branch/master/graphs/sunburst.svg
