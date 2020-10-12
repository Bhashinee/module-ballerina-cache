Ballerina Cache Library
===================

  [![Build](https://github.com/ballerina-platform/module-ballerina-cache/workflows/PR%20build/badge.svg)](https://github.com/ballerina-platform/module-ballerina-cache/actions?query=workflow%3ABuild)
  [![Daily build](https://github.com/ballerina-platform/module-ballerina-cache/workflows/Daily%20build/badge.svg)](https://github.com/ballerina-platform/module-ballerina-cache/actions?query=workflow%3ABuild)
  [![GitHub Last Commit](https://img.shields.io/github/last-commit/ballerina-platform/module-ballerina-cache.svg)](https://github.com/ballerina-platform/module-ballerina-cache/commits/master)
  [![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

The cache library is one of the standard library modules of the<a target="_blank" href="https://ballerina.io/"> Ballerina</a> language.

This module provides APIs for handle caching in Ballerina. It consists of a default implementation based on the map data structure. It also provides a default cache eviction policy object, which is based on the LRU eviction algorithm.

For more information on all the operations supported by the `cache`, which include the below, go to [The Cache Module](https://ballerina.io/swan-lake/learn/api-docs/ballerina/cache/).

- put
- get
- invalidate
- invalidateAll
- hasKey
- keys
- size
- capacity

For example demonstrations of the usage, go to [Ballerina By Examples](https://ballerina.io/swan-lake/learn/by-example/mysql-init-options.html).

## Building from the Source

### Setting Up the Prerequisites

1. Download and install Java SE Development Kit (JDK) version 11 (from one of the following locations).
   * [Oracle](https://www.oracle.com/java/technologies/javase-jdk11-downloads.html)
   
   * [OpenJDK](https://adoptopenjdk.net/)
   
        > **Note:** Set the JAVA_HOME environment variable to the path name of the directory into which you installed JDK.
     
### Building the Source

Execute the commands below to build from source.

1. To build the library,
        
        ./gradlew clean build

2. To build the module without tests,

        ./gradlew clean build -PskipBallerinaTests

3. To debug the tests,

        ./gradlew clean build -PdebugBallerina=<port>

## Contributing to Ballerina

As an open source project, Ballerina welcomes contributions from the community. 

You can also check for [open issues](https://github.com/ballerina-platform/module-ballerina-sql/issues) that interest you. We look forward to receiving your contributions.

For more information, go to the [contribution guidelines](https://github.com/ballerina-platform/ballerina-lang/blob/master/CONTRIBUTING.md).

## Code of Conduct

All contributors are encouraged to read the [Ballerina Code of Conduct](https://ballerina.io/code-of-conduct).

## Useful Links

* Discuss about code changes of the Ballerina project in [ballerina-dev@googlegroups.com](mailto:ballerina-dev@googlegroups.com).
* Chat live with us via our [Slack channel](https://ballerina.io/community/slack/).
* Post all technical questions on Stack Overflow with the [#ballerina](https://stackoverflow.com/questions/tagged/ballerina) tag.
