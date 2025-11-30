# Personal Notes

## Communication

We are using `request` function of `vim.lsp.Client` function to communicate with
the `jdtls`.

```lua
fun(method: string, params: table?, handler: lsp.Handler?, bufnr: integer?): boolean, integer?`)
```

This has almost 1 to 1 mapping with `vscode` APIs most of the time.

```typescript
await this.languageClient.sendRequest(
  method: string,
  params: any,
  // handler is not passed since there is async / await
  // buffer I'm guessing is set to current buffer by default???
);
```

However, some APIs sends more arguments, to which we don't have a Neovim lua
equivalent I'm guessing. Following is an example.

```typescript
await this.languageClient.sendRequest(
  CompileWorkspaceRequest.type,
  isFullCompile,
  token,
);
```

To make this request, probably `client.rpc.request` should be used without
`request()` wrapper.
