// Copyright (c) 2020 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/task;
import ballerina/time;

# The `LRU` eviction algorithm.
public const LRU = "Least Recently Used";
# The `FIFO` eviction algorithm.
public const FIFO = "First In First Out";

# The collection of eviction algorithms.
public type EvictionPolicy LRU|FIFO;

# Represents cache configuration.
#
# + capacity - Maximum number of entries allowed
# + evictionPolicy - The policy which defines the cache eviction algorithm
# + evictionFactor - The factor which the entries will be evicted once the cache full
# + defaultMaxAgeInSeconds - The default value in seconds which all the cache entries are valid.
#                            '-1' means, the entries are valid forever.
#                            This will be overwritten by the the `maxAge` property set when inserting item to cache
# + cleanupIntervalInSeconds - Interval of the timer task which clean up the cache
public type CacheConfig record {|
    int capacity = 100;
    EvictionPolicy evictionPolicy = LRU;
    float evictionFactor = 0.25;
    int defaultMaxAgeInSeconds = -1;
    int cleanupIntervalInSeconds?;
|};

type CacheEntry record {|
    string key;
    any data;
    int expTime;       // exp time since epoch. calculated based on the `maxAge` parameter when inserting to map
|};

// TODO: Remove by fixing https://github.com/ballerina-platform/ballerina-lang/issues/21268
type MapAndList record {|
    map<Node> entries;
    LinkedList list;
|};

// Cleanup service which cleans the cache entries periodically.
boolean cleanupInProgress = false;

// Cleanup service which cleans the cache entries periodically.
service cleanupService = service {
    resource function onTrigger(MapAndList mapAndList) {
        // This check will skip the processes triggered while the clean up in progress.
        if (!cleanupInProgress) {
            lock {
                cleanupInProgress = true;
                cleanup(mapAndList);
                cleanupInProgress = false;
            }
        }
    }
};

# Represents Ballerina `Cache` object and cache related operations.
public type Cache object {

    *AbstractCache;

    private int capacity;
    private EvictionPolicy evictionPolicy;
    private float evictionFactor;
    private int defaultMaxAgeInSeconds;
    private map<Node> entries = {};
    private LinkedList list;

    # Creates a new `Cache` object.
    #
    # + cacheConfig - Cache configurations
    public function __init(CacheConfig cacheConfig = {}) {
        self.capacity = cacheConfig.capacity;
        self.evictionPolicy = cacheConfig.evictionPolicy;
        self.evictionFactor = cacheConfig.evictionFactor;
        self.defaultMaxAgeInSeconds = cacheConfig.defaultMaxAgeInSeconds;

        // Cache capacity must be a positive value.
        if (self.capacity <= 0) {
            panic prepareError("Capacity must be greater than 0.");
        }
        // Cache eviction factor must be between 0.0 (exclusive) and 1.0 (inclusive).
        if (self.evictionFactor <= 0 || self.evictionFactor > 1) {
            panic prepareError("Cache eviction factor must be between 0.0 (exclusive) and 1.0 (inclusive).");
        }

        // Cache eviction factor must be between 0.0 (exclusive) and 1.0 (inclusive).
        if (self.defaultMaxAgeInSeconds != -1 && self.defaultMaxAgeInSeconds <= 0) {
            panic prepareError("Default max age should be greater than 0 or -1 for indicate forever valid.");
        }

        self.list = {
            head: (),
            tail: ()
        };
        int? cleanupIntervalInSeconds = cacheConfig?.cleanupIntervalInSeconds;
        if (cleanupIntervalInSeconds is int) {
            task:TimerConfiguration timerConfiguration = {
                intervalInMillis: cleanupIntervalInSeconds,
                initialDelayInMillis: cleanupIntervalInSeconds
            };
            task:Scheduler cleanupScheduler = new(timerConfiguration);
            MapAndList mapAndList = {
                entries: self.entries,
                list: self.list
            };
            task:SchedulerError? result = cleanupScheduler.attach(cleanupService, attachment = mapAndList);
            if (result is task:SchedulerError) {
                panic prepareError("Failed to create the cache cleanup task.", result);
            }
            result = cleanupScheduler.start();
            if (result is task:SchedulerError) {
                panic prepareError("Failed to start the cache cleanup task.", result);
            }
        }
    }

    # Add the given key, value pair to the cache.
    #
    # + key - Key of the cached value
    # + value - Value to be cached
    # + maxAgeInSeconds - The value in seconds which the cache entry is valid. '-1' means, the entry is valid forever.
    public function put(string key, any value, int maxAgeInSeconds = -1) {
        lock {
            // If the current cache is full (i.e. size = capacity), evict cache.
            if (self.size() == self.capacity) {
                evict(self.entries, self.list, self.evictionPolicy, self.capacity, self.evictionFactor);
            }

            // Calculate the `expTime` of the cache entry based on the `maxAgeInSeconds` property and
            // `defaultMaxAgeInSeconds` property.
            int calculatedExpTime = -1;
            if (maxAgeInSeconds != -1 && maxAgeInSeconds > 0) {
                calculatedExpTime = time:nanoTime() + (maxAgeInSeconds * 1000 * 1000 * 1000);
            } else {
                if (self.defaultMaxAgeInSeconds != -1) {
                    calculatedExpTime = time:nanoTime() + (self.defaultMaxAgeInSeconds * 1000 * 1000 * 1000);
                }
            }

            CacheEntry entry = {
                key: key,
                data: value,
                expTime: calculatedExpTime
            };
            Node newNode = { value: entry };

            if (self.hasKey(key)) {
                Node oldNode = self.entries.get(key);
                putOnEvictionPolicy(self.evictionPolicy, self.list, newNode, oldNode);
            } else {
                putOnEvictionPolicy(self.evictionPolicy, self.list, newNode);
            }
            self.entries[key] = newNode;
        }
    }

    # Return the cached value associated with the given key.
    #
    # + key - Key which is used to retrieve the cached value
    # + return - The cached value associated with the given key or
    # `Error` if the provided cache key is not or if any error occurred while retrieving from the cache.
    public function get(string key) returns any|Error {
        lock {
            if (!self.hasKey(key)) {
                return prepareError("Cache entry from the given key: " + key + ", is not available.");
            }

            Node node = self.entries.get(key);
            CacheEntry entry = <CacheEntry>node.value;

            // Check whether the cache entry is already expired. Even though the cache cleaning task is configured
            // and runs in predefined intervals, sometimes the cache entry might not have been removed at this point
            // even though it is expired. So this check guarantees that the expired cache entries will not be returned.
            if (entry.expTime != -1 && entry.expTime < time:nanoTime()) {
                remove(self.list, node);
                return removeEntry(self.entries, key);
            }

            getOnEvictionPolicy(self.evictionPolicy, self.list, node);
            return entry.data;
        }
    }

    # Invalidate a cached value from the cache.
    #
    # + key - Key of the cache entry which needs to be invalidate
    # + return - `()` if successfully invalidated or
    # `Error` if the provided cache key is not or if any error occurred while invalidating from the cache.
    public function invalidate(string key) returns Error? {
        lock {
            if (!self.hasKey(key)) {
                return prepareError("Cache entry from the given key: " + key + ", is not available.");
            }

            Node node = self.entries.get(key);
            remove(self.list, node);
            return removeEntry(self.entries, key);
        }
    }

    # Invalidate all the cached values from the cache.
    #
    # + return - `()` if successfully invalidated all or
    # `Error` if any error occurred while invalidating all from the cache.
    public function invalidateAll() returns Error? {
        lock {
            clear(self.list);
            return removeAllEntries(self.entries);
        }
    }

    # Checks whether the given key has an associated cache value.
    #
    # + key - The key to be checked
    # + return - Whether the an associated cache value is available in the cache or not
    public function hasKey(string key) returns boolean {
        return self.entries.hasKey(key);
    }

    # Returns all keys from the cache.
    #
    # + return - Array of all keys from the cache
    public function keys() returns string[] {
        return self.entries.keys();
    }

    # Returns the size of the cache.
    #
    # + return - The size of the cache
    public function size() returns int {
        return self.entries.length();
    }

    # Returns the capacity of the cache.
    #
    # + return - The capacity of the cache
    public function capacity() returns int {
        return self.capacity;
    }
};

function evict(map<Node> entries, LinkedList list, EvictionPolicy evictionPolicy, int capacity, float evictionFactor) {
    int evictionKeysCount = <int>(capacity * evictionFactor);
    match (evictionPolicy) {
        LRU|FIFO => {
            foreach int i in 1...evictionKeysCount {
                Node? tail = removeLast(list);
                if (tail is Node) {
                    CacheEntry entry = <CacheEntry>tail.value;
                    Error? result = removeEntry(entries, entry.key);
                    // The return result (error which occurred due to unavailability of the key or nil) is ignored
                    // since no purpose of handling it.
                } else {
                    break;
                }
            }
        }
    }
}

function putOnEvictionPolicy(EvictionPolicy evictionPolicy, LinkedList list, Node newNode, Node? oldNode = ()) {
    match (evictionPolicy) {
        LRU => {
            if (!(oldNode is ())) {
                remove(list, oldNode);
            }
            addFirst(list, newNode);
        }
        FIFO => {
            addFirst(list, newNode);
        }
    }
}

function getOnEvictionPolicy(EvictionPolicy evictionPolicy, LinkedList list, Node node) {
    match (evictionPolicy) {
        LRU => {
            remove(list, node);
            addFirst(list, node);
        }
        FIFO => {
            return;
        }
    }
}

function cleanup(MapAndList mapAndList) {
    if (mapAndList.entries.length() == 0) {
        return;
    }
    foreach Node node in mapAndList.entries {
        CacheEntry entry = <CacheEntry>node.value;
        if (entry.expTime != -1 && entry.expTime < time:nanoTime()) {
            remove(mapAndList.list, node);
            Error? result = removeEntry(mapAndList.entries, entry.key);
            // The return result (error which occurred due to unavailability of the key or nil) is ignored
            // since no purpose of handling it.
            return;
        }
    }
}

function removeEntry(map<Node> entries, string key) returns Error? {
    var result = trap entries.remove(key);
    if (result is error) {
        return prepareError("Error while removing the entry (key: " + key + ") from the map. ", result);
    }
}

function removeAllEntries(map<Node> entries) returns Error? {
    var result = trap entries.removeAll();
    if (result is error) {
        return prepareError("Error while removing all the entries from the map.", result);
    }
}