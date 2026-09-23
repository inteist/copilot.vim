# GitHub Copilot for Vim and Neovim

> **Fork note.** This fork changes what `<Tab>` does: one press accepts a
> single word, and a second press within `g:copilot_double_tab_timeout`
> milliseconds (300 by default) accepts the rest of the suggestion. Set the
> timeout to 0 for word-at-a-time only. See `:help copilot-i_<Tab>`, and
> `test/double-tab.vim` for the regression tests. It also carries one fix to
> the Neovim transport, so that a `false` or null result no longer reads as a
> malformed response (`test/null-result.vim`). Everything else tracks upstream
> `release`.

GitHub Copilot is an AI pair programmer tool that helps you write code faster
and smarter. Trained on billions of lines of public code, GitHub Copilot turns
natural language prompts including comments and method names into coding
suggestions across dozens of languages.

Copilot.vim is a Vim/Neovim plugin for GitHub Copilot.

To learn more, visit
<https://github.com/features/copilot>.

## Getting access to GitHub Copilot

To access GitHub Copilot, an active GitHub Copilot subscription is required.
Sign up for [GitHub Copilot Free](https://github.com/settings/copilot), or
request access from your enterprise admin.

## Getting started

1. Install [Neovim](https://github.com/neovim/neovim/releases/latest) or the latest patch of [Vim](https://github.com/vim/vim) (9.0.0185 or newer).

2. Install [Node.js](https://nodejs.org/en/download/).  If you use a package manager, make sure to install
   NPM as well (e.g., `apt install nodejs npm` on Debian/Ubuntu).

3. Install `github/copilot.vim` using vim-plug, lazy.nvim, or any other
   plugin manager.  Or to install manually, run one of the following
   commands:

   * Vim, Linux/macOS:

     ```
     git clone --depth=1 https://github.com/github/copilot.vim.git \
       ~/.vim/pack/github/start/copilot.vim
     ```

   * Neovim, Linux/macOS:

     ```
     git clone --depth=1 https://github.com/github/copilot.vim.git \
       ~/.config/nvim/pack/github/start/copilot.vim
     ```

   * Vim, Windows (PowerShell command):

     ```
     git clone --depth=1 https://github.com/github/copilot.vim.git `
       $HOME/vimfiles/pack/github/start/copilot.vim
     ```

   * Neovim, Windows (PowerShell command):

     ```
     git clone --depth=1 https://github.com/github/copilot.vim.git `
       $HOME/AppData/Local/nvim/pack/github/start/copilot.vim
     ```

4. Start Vim/Neovim and invoke `:Copilot setup`.

Suggestions are displayed inline and can be accepted by pressing the tab key.
See `:help copilot` for more information.

## Troubleshooting

We’d love to get your help in making GitHub Copilot better!  If you have
feedback or encounter any problems, please reach out on our [feedback
forum](https://github.com/github/copilot.vim/issues).
