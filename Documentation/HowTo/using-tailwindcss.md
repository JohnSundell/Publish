# How to use TailwindCSS with John Sundell's Publish

Last Tended On: Dec 20, 2020 4:24 PM

TailwindCSS is one of my favorite frameworks to use, and I'd love to use it with John Sundell's Publish. Here's how you would do it!

So the naive way to do it would be to install the complete `tailwind.css` as part of your resources in your theme. This'll work but TailwindCSS is huge: 3020.7kB uncompressed. It also doesn't let you access all the configuration available with a tailwind config file. But if you wanted to, the command is this:

```bash
npx tailwindcss-cli@latest build -o styles.css
```

This'll create a styles.css file that you can just include as part of your theme:

```swift
public extension Theme {
    static var tailwind: Self {
        Theme(
            htmlFactory: FoundationHTMLFactory(),
            resourcePaths: ["path/to/styles.css"]
        )
    }
}
```

However, if you want to get all the fancy stuff, we're gonna have to put in a little more work. Specifically, the workflow is this: we'll create an npm package in the same directory as our website, and then use PostCSS to compile our css files using Tailwind as a plugin. The Tailwind plugin lets us use a Tailwind config file as well as purge all unused styles, so that our css will be tiny in comparison.

First we'll want to create an npm package in the root directory of our website. You'll want to specify "main" as "Output/index.html" and the scripts part doesn't matter.

```bash
npm init
```

This will create a `package.json` for you. Next install the required dependencies:

```bash
npm install --save-dev postcss@latest tailwind@latest autoprefixer@latest postcss-cli
```

Create a file `postcss.config.js` (in the same root directory) that identifies our plugins:

```jsx
module.exports = {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
};
```

and run

```bash
npx tailwindcss init
```

which will create our tailwind configuration file at `tailwind.config.js`. You can supply all the tailwind configuration you want here. Since we want to purge all the unused styles when we compile the css, we'll provide the configuration file where we want it to search for styles to purge

```bash
module.exports = {
    purge: ['./Output/**/*.html'],
    ...
}
```

This tells tailwind to look through all the files matching that glob pattern (so all html files in `Output` directory) for the classes it needs. Then, when compiling the css, it'll remove all the styles from the huge tailwind file that were never used in your html files.

Finally, we're gonna need to make our styles file that imports tailwind styles. Just add this little snippet to the top of any `styles.css` being used by your Publish Theme:

```bash
@tailwind base;
@tailwind components;
@tailwind utilities;
```

This sets up our project to use tailwind correctly! To automate the css compilation every time you generate your website add this script to your npm package:

```bash
{
    "scripts": {
        ...
    "build": "publish generate;NODE_ENV=production postcss Output/styles.css --replace;NODE_ENV=production postcss Output/theme/styles.css --replace"
  }
}
```

This needs a little bit of explanation. First it runs `publish generate` which will generate your website. If you check your `Output/styles.css` file at this point, it'll still have the tailwind imports on top of it. Next it uses `postcss` to compile the styles file. The `--replace` flag means that the compilation happens in-place. Since tailwind only purges unused styles when building for production, you need to explicitly set the environment variable `NODE_ENV` to production since that's not the default. After it compiles you should see that your `Output/styles.css` has now been swapped out with tailwind's css. Next we repeat the same process for `Output/theme/styles.css`. Note this assumes your `styles.css` file was put in `Resources/theme/styles.css`. Idk why Publish has two places it keeps the same css file,

That's it! Run `npm run build` and you'll see your website properly purge and use tailwind styles according to your config. Note that you cannot use the default `publish run` with that method; that regenerates the website before serving, so the css compilation step doesn't happen. To use this, I forked Publish and created a new CLI utility called `serve` that will serve the website without regenerating it first. It's available here: [https://github.com/moonrise-tk/Publish](https://github.com/moonrise-tk/Publish). Just download the repo and install the CLI the same as you did when you first installed publish. Now you'll have a new command to use `publish serve` that'll just serve the website. I opened a pull request, so hopefully it'll just be available with the default Publish in the future.


