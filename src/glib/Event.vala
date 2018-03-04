/*
 * Copyright 2018 Jiří Janoušek <janousek.jiri@gmail.com>
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this
 *    list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

namespace Drt {

public class Event {
    private bool flag = false;
    private Mutex mutex = Mutex();
    private Cond condition = Cond();

    public Event(bool is_set = false) {
        this.flag = is_set;
    }

    public bool is_set() {
        mutex.lock();
        bool result = flag;
        mutex.unlock();
        return result;
    }

    public void wait() {
        mutex.lock();
        // Wait must be used in a loop, see docs for details
        while (!flag) {
            condition.wait(mutex);
        }
        mutex.unlock();
    }

    public bool wait_until(int64 end_time) {
        mutex.lock();
        // Wait must be used in a loop, see docs for details
        while (!flag) {
            if (!condition.wait_until(mutex, end_time)) {
                mutex.unlock();
                return false;
            }
        }
        mutex.unlock();
        return true;
    }

    public bool wait_for(int64 microseconds) {
        return wait_until(GLib.get_monotonic_time() + microseconds);
    }

    public void set() {
        mutex.lock();
        if (!flag) {
            flag = true;
            condition.broadcast();
        }
        mutex.unlock();
    }

    public void clear() {
        mutex.lock();
        flag = false;
        mutex.unlock();
    }
}

} // namespace Drt
