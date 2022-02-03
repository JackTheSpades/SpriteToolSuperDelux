# CONTRIBUTING

## General rules:

- Decently descriptive commit messages (with descriptions if necessary).
- The GitHub actions runner on Ubuntu does a quite expensive test on each run. This can be skipped by adding `[NoTest]` at the beginning of the title of the commit message. This is recommended to add when your changes only affect the CFG Editor, since the expensive test only affects Pixi.
- Use spaces for everything, no tabs. 4 spaces per tab.
- Avoid breaking changes unless they give a huge benefit.
- Don't be rude and don't insult/disrespect other people's code.

Since this is a multi-part project I'll illustrate rules based on language.

Note that newer code follows these rules. 
Since this project passed in multiple people's hands, some old code will not follow these rules.
This however does not mean you shouldn't follow them. 
All of the old code will get converted to rule-following code sooner or later.

## ASM:

For asm files, the following rules apply:

- !snake_case for defines
- %PascalCase() for macros/functions
- camelCase for labels
- Have label names be descriptive
- Avoid abbreviations if you can unless they're very widely used, keep names of everything under 30 characters
- Try to always separate sub-routines into macros when possible if you want to avoid the cost of JSR-RTS but still reap the benefits of the readability of separation
- Use +/- labels sparingly, use them only when skipping a single instruction, 2 at most, and only a single level, seeing ++++ only makes code hard to read
- Avoid loading magic constants (e.g. LDA #$45), give them a define name that states clearly what they are
- Keep things containerized, don't let macro bleed out labels in the top level, use macro labels
- Indent code by 4 spaces even at top level, code all the way at the left of the page is weird, labels can be at the very left
- Avoid comments unless absolutely necessary, especially in the middle of code

## C++:

For C++ files, the following rules apply:

- Use modern C++ code style. Prefer newer C++17/C++20 idioms over old C-style code
- Don't abuse templates too much
- Don't `using namespace std;`
- Don't use external libraries unless you have to (e.g. writing an entire json parser)
- Avoid abusing the preprocessor to hell and back (macro galore is a no-no)
- If you can use the `std::` for something, use it, don't reinvent the wheel

## C#:

For C# files, the following rules apply:

- Don't misuse LINQ
- Keep the same style as existing code
- Keep the code as simple as you can and touch it as little as possible
