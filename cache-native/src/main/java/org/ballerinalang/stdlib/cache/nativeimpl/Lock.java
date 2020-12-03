/*
 * Copyright (c) 2020, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 * WSO2 Inc. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package org.ballerinalang.stdlib.cache.nativeimpl;

import java.util.concurrent.atomic.AtomicBoolean;

/**
 * Class to handle concurrency behaviour of `LinkedList` using compare and swap technique.
 */
public class Lock {
    private static AtomicBoolean locked;
    private static AtomicBoolean cleanupLocked;

    public static void init() {
        locked = new AtomicBoolean(false);
    }

    public static boolean tryLock() {
        return locked.compareAndSet(false, true);
    }

    public static void releaseLock() {
        locked.set(false);
    }

    public static void cleanupInit() {
        cleanupLocked = new AtomicBoolean(false);
    }

    public static boolean cleanupTryLock() {
        return cleanupLocked.compareAndSet(false, true);
    }

    public static void cleanupReleaseLock() {
        cleanupLocked.set(false);
    }
}
