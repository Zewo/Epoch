/* -*-c-*-
   The MIT License (MIT)

   Copyright (c) 2017 - Zewo

   Permission is hereby granted, free of charge, to any person obtaining a copy
   of this software and associated documentation files (the "Software"), to deal
   in the Software without restriction, including without limitation the rights
   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
   copies of the Software, and to permit persons to whom the Software is
   furnished to do so, subject to the following conditions:

   The above copyright notice and this permission notice shall be included in all
   copies or substantial portions of the Software.

   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
   SOFTWARE.

   Created: 2017-01-13 by Ronaldo Faria Lima

   This file purpose: Sigaction wrapper function
*/

#include <signal.h>
#include <errno.h>
#include <stdio.h>
#include "include/posix.h"

/*
 * This function installs a signal handler based on provided options.
 *
 * Parameters:
 *
 * - signal: Signal do install the handler for. See signal.h for SIG* macros.
 * - option: How to install the handle:
 *     - 0: Ignore the signal. If delivered to the process, will be ignored.
 *     - 1: Use default handler. 
 *     - 2: Installs a user provided callback.
 * - handler: Callback to be used if option = 2
 *
 * Returns:
 * - 0x0 on success
 * - EINVAL if some of the provided parameters are invalid
 * 
 */

int
CPOSIXInstallSignalHandler(int signal, int option, cposix_signal_handler handler)
{
  struct sigaction action;

  switch (option)
    {
    case 0: /* Ignore signal delivery */
      action.sa_handler = SIG_IGN;
      break;
    case 1: /* Use default handler */
      action.sa_handler = SIG_DFL;
      break;
    case 2: /* Pass signal processing to provided handler */
      if (handler == NULL)
        {
          errno = EINVAL;
          return EINVAL;
        }
      action.sa_handler = handler;
      break;
    default:
      errno = EINVAL;
      return EINVAL;
    }
  sigemptyset(&action.sa_mask);
  sigaction(signal, &action, NULL);
  return 0x0;
}
