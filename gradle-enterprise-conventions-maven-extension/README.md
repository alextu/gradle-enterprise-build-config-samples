# Example Gradle Enterprise Conventions Maven Extension

This project demonstrates how to share a common Gradle Enterprise configuration across multiple Maven projects. It is intended to serve as a starting point for creating your own extension to apply your specific Gradle Enterprise configuration.

## Usage

* Use a [Repository Manager](https://maven.apache.org/repository-management.html) as a [Mirror](https://maven.apache.org/guides/mini/guide-mirror-settings.html) to Maven Central
* Create your own copy of the `extension` project
* Address all `todo` comments
    * Update the `groupId` and `artifactId` in the [POM](extension/pom.xml) file
    * Update the package containing source files
    * Update `isCi` in [CiUtils.java](extension/src/main/java/com/example/CiUtils.java) and the CI checks in the [Gradle Enterprise configuration](extension/.mvn/gradle-enterprise.xml) to properly detect your CI environment
    * Update the server URL to your own Gradle Enterprise instance in the [Gradle Enterprise configuration](extension/.mvn/gradle-enterprise.xml) and [CustomGradleEnterpriseConfig.java](extension/src/main/java/com/example/CustomGradleEnterpriseConfig.java)
* Add any common tags, links, or values to [CustomGradleEnterpriseConfig.java](extension/src/main/java/com/example/CustomGradleEnterpriseConfig.java)
* Deploy the extension to your Repository Manager.
* Utilize the extension in your projects by adding the following to your `.mvn/extensions.xml' file, adjusted for your own groupId and artifactId:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<extensions xmlns="http://maven.apache.org/EXTENSIONS/1.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xsi:schemaLocation="http://maven.apache.org/EXTENSIONS/1.0.0 http://maven.apache.org/xsd/core-extensions-1.0.0.xsd">
  <extension>
    <groupId>com.example</groupId>
    <artifactId>gradle-enterprise-conventions-maven-extension</artifactId>
    <version>1.0</version>
  </extension>
</extensions>
```

## Contents

This project contains the following:

* `extension` - Contains the example convention extension that applies and configures Gradle Enterprise on projects
* `example-build` - An example build that applies the convention extension

### Running the example builds

Before running the example builds, publish the sample extension to your local Maven repository:

```bash
cd extension
./mvnw clean install
```

Once the extension is published, then you can run the example build under `example-build` using the Maven wrapper:

```bash
cd example-build
./mvnw clean verify
```

## Differences with the Common Custom User Data Maven extension
This extension differs from the [Common Custom User Data Maven Extension](https://github.com/gradle/common-custom-user-data-maven-extension) in that this also applies the Gradle Enterprise extension and some custom configuration. The Common Custom User Data Maven Extension does not apply the extension, but rather assumes the extension has already been applied when it is used). This extension is a sample meant to be copied rather than an extension that should be used directly.
