# create a dashboard for admin portal creation using the svelte framwework
To create a dashboard for an admin portal using the Svelte framework, you can follow these steps:
1. Create the components under the `src/main/java/resources` directory.

example:
```markdown
Svelte
We added a Web Bundler + Svelte extension which makes it very easy to use Svelte with Quarkus.

Svelte is a UI framework that uses a compiler to let you write breathtakingly concise javascript components that do minimal work in the browser, using languages you already know — HTML, CSS and JavaScript. It may be used to create Javascript components for Qute for example.

Installation
If you want to use this extension, you need to add the io.quarkiverse.web-bundler:quarkus-web-bundler-svelte extension first to your build file.

For instance, with Maven, add the following dependency to your POM file:

<dependency>
    <groupId>io.quarkiverse.web-bundler</groupId>
    <artifactId>quarkus-web-bundler-svelte</artifactId>
    <version>2.3.3</version>
</dependency>
With Gradle, you need to add this plugin (to allow architecture based resolution) and the dependency:

plugins {
  id("io.mvnpm.gradle.plugin.native-java-plugin") version "1.0.0"
}



dependencies {
    implementation("io.quarkiverse.web-bundler:quarkus-web-bundler-svelte:2.3.3")
}
Usage
There is no need to add the Svelte mvnpm dependency in your project when using custom elements (configurable).

In your web directory:

web/App.svelte
<svelte:options customElement="my-component" />
<script>
	let count = $state(0);

	function increment() {
		count += 1;
	}
</script>

<button onclick={increment}>
	Clicked {count}
	{count === 1 ? 'time' : 'times'}
</button>
Configuration
 Configuration property fixed at build time - All other configuration properties are overridable at runtime

Configuration property

Type

Default

 quarkus.web-bundler.svelte.custom-element

Determines whether the Svelte component should be compiled as a custom element (Web Component).

When enabled, the component is wrapped in a standard Custom Element interface, allowing it to be used natively in HTML without requiring the Svelte runtime.

See: Custom Elements Documentation

When disabled, add the org.mvnpm:svelte:provided dependency to your project POM and include the following in your app.js script to mount the component:

`import ++{++ mount` from "svelte";
import MyComponent from "./MyComponent.svelte";

mount(MyComponent, { target: document.querySelector("#target") });
}
Environment variable: QUARKUS_WEB_BUNDLER_SVELTE_CUSTOM_ELEMENT

boolean

true

Server-Side Qute Components
When you need to include custom scripts or styles in your Qute tags, Server-Side Qute Components provides an elegant solution.

This requires quarkus-qute or quarkus-qute-web in the project (and this is not made to be used with the build-time template rendering).
To enable server-side components, add this in the application.properties:

quarkus.web-bundler.bundle.components=true
quarkus.web-bundler.bundle.components.key=app 
quarkus.web-bundler.bundle.components.qute-tags=true 
use app to have a single merged bundle with the app (or remove this line to use components as default)
activate qute-tags support (default is false)
Here is a nice convention to define your components: src/main/resources/web/components/[name]/[name].{html,css,scss,js,ts,…​};. The scripts, styles and assets will be bundled, the html template will be usable as a Qute tag.

Example: - src/main/resources/web/components/hello/hello.html - src/main/resources/web/components/hello/hello.js - src/main/resources/web/components/hello/hello.scss

This way you can use {#hello} in your templates and the scripts & styles will be bundled.

You may create different qute components groups to be used in different pages.

```

Use the above example to create components and reuse them in the portal.

Use the `./kotlin` directory for the reference of the ui developed using the kotlin framework.
You can use the code reference in kvsion to create the same UI using the Svelte framework. The components can be created in the `src/main/resources/web/components` directory and can be reused across different pages of the admin portal.



