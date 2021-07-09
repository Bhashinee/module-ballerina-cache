/*
 * Copyright (c) 2021, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 * WSO2 Inc. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */
package io.ballerina.stdlib.cache.nativeimpl.concurrentlinkedhashmap;

/**
 * A class that can determine the weight of a value. The total weight threshold is used to
 * determine when an eviction is required.
 */
interface Weigher<V> {

    /**
     * Measures an object's weight to determine how many units of capacity that the value
     * consumes. A value must consume a minimum of one unit.
     *
     * @param value the object to weigh
     * @return the object's weight
     */
    int weightOf(V value);
}
