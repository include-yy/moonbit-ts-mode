# moonbit-mode

> [!WARNING]
> Still in early stage development, use with caution

## Prerequisites

- Emacs 31 with Tree-sitter support
- Build MoonBit grammars for Emacs:
    ``` shell
    git clone git@github.com:moonbitlang/tree-sitter-moonbit.git
    cd tree-sitter-moonbit/src
    cc -fPIC -c -I. parser.c
    cc -fPIC -c -I. scanner.c
    cc -fPIC -shared *.o -o libtree-sitter-moonbit.so
    mv libtree-sitter-moonbit.so ~/.emacs.d/tree-sitter/
    ```

## Install

You can either:

- Clone this repo, add the `moonbit-ts-mode.el` file to your Emacs
  `load-path`: 
  ``` elisp
  (add-to-list 'load-path "/path/to/moonbit-ts-mode")
  ```
- With `package-vc`:
  ``` 
  M-x package-vc-install "https://github.com/include-yy/moonbit-ts-mode"
  ```
