# Changelog

## [3.0.0](https://github.com/nvim-java/nvim-java/compare/v2.1.2...v3.0.0) (2025-08-06)


### Features

* [@logrusx](https://github.com/logrusx) adds Mason 2.0 support ([#402](https://github.com/nvim-java/nvim-java/issues/402)) ([58c25cd](https://github.com/nvim-java/nvim-java/commit/58c25cd45d867fc512af48a457c71bb26d9d778d))


### Miscellaneous Chores

* release 3.0.0 ([3cecf73](https://github.com/nvim-java/nvim-java/commit/3cecf7362e5f83e4a34e84e4f14c65bad81968f1))

## [2.1.2](https://github.com/nvim-java/nvim-java/compare/v2.1.1...v2.1.2) (2025-08-04)


### Bug Fixes

* java-debug-adapter doean't install ([#407](https://github.com/nvim-java/nvim-java/issues/407)) ([2776094](https://github.com/nvim-java/nvim-java/commit/2776094c745af0d99b5acb24a4594d85b4f99545))
* mason registry verification fails ([#405](https://github.com/nvim-java/nvim-java/issues/405)) ([4fd68c4](https://github.com/nvim-java/nvim-java/commit/4fd68c4025acaafb9efbf2e0cf69e017bcc4476c))
* **typo:** project vise -&gt; project-wise ([#390](https://github.com/nvim-java/nvim-java/issues/390)) ([7c2e81c](https://github.com/nvim-java/nvim-java/commit/7c2e81caa301b0d1bc7992b88981af883b3b5d6b))

## [2.1.1](https://github.com/nvim-java/nvim-java/compare/v2.1.0...v2.1.1) (2025-02-16)


### Bug Fixes

* nvim-java mason reg is not added if the mason is not merging parent config in user end ([#355](https://github.com/nvim-java/nvim-java/issues/355)) ([db54fbf](https://github.com/nvim-java/nvim-java/commit/db54fbf6a022f2720f86c6b6d7383ba501211b80))

## [2.1.0](https://github.com/nvim-java/nvim-java/compare/v2.0.2...v2.1.0) (2025-01-26)


### Features

* add sync ui select util ([#345](https://github.com/nvim-java/nvim-java/issues/345)) ([c616f72](https://github.com/nvim-java/nvim-java/commit/c616f72fa2ea0ad9d7798e1d7cab56aa6de56108))


### Bug Fixes

* **dap:** do not override previously defined user config ([#342](https://github.com/nvim-java/nvim-java/issues/342)) ([4d810a5](https://github.com/nvim-java/nvim-java/commit/4d810a546c262ca8f60228dc98ba51f81f5649c6))

## [2.0.2](https://github.com/nvim-java/nvim-java/compare/v2.0.1...v2.0.2) (2024-12-24)


### Bug Fixes

* runner cmd [#241](https://github.com/nvim-java/nvim-java/issues/241) ([#329](https://github.com/nvim-java/nvim-java/issues/329)) ([a36f50c](https://github.com/nvim-java/nvim-java/commit/a36f50c82f922f352d4ce7ac6a3c6b238b3e0a36))

## [2.0.1](https://github.com/nvim-java/nvim-java/compare/v2.0.0...v2.0.1) (2024-08-01)


### Bug Fixes

* refactor and build lua API being registered incorrectly ([#284](https://github.com/nvim-java/nvim-java/issues/284)) ([b9e6b71](https://github.com/nvim-java/nvim-java/commit/b9e6b71c8cbb3f6db8ce7d3a9bd3f3cb805156f1))

## [2.0.0](https://github.com/nvim-java/nvim-java/compare/v1.21.0...v2.0.0) (2024-07-25)


### ⚠ BREAKING CHANGES

* move all the client commands to nvim-refactor repo ([#278](https://github.com/nvim-java/nvim-java/issues/278))

### Code Refactoring

* move all the client commands to nvim-refactor repo ([#278](https://github.com/nvim-java/nvim-java/issues/278)) ([1c04d72](https://github.com/nvim-java/nvim-java/commit/1c04d72d10a4807583096848dc6ad92192a94ee1))

## [1.21.0](https://github.com/nvim-java/nvim-java/compare/v1.20.0...v1.21.0) (2024-07-15)


### Features

* adding delegate method generate code action ([9462546](https://github.com/nvim-java/nvim-java/commit/94625466f5023719c3625438fcf95f75f7d0c02d))

## [1.20.0](https://github.com/nvim-java/nvim-java/compare/v1.19.0...v1.20.0) (2024-07-14)


### Features

* add generate hash code and equals code action ([6a714fe](https://github.com/nvim-java/nvim-java/commit/6a714fedc4a8a327d2acebe34d673b768dcbb0d8))

## [1.19.0](https://github.com/nvim-java/nvim-java/compare/v1.18.0...v1.19.0) (2024-07-14)


### Features

* add clean workspace command ([8a1171c](https://github.com/nvim-java/nvim-java/commit/8a1171cc21aaae58f8a08759562814aea87e694d))
* add toString code action ([4b1e1bd](https://github.com/nvim-java/nvim-java/commit/4b1e1bd5206174b8914858d085fe6809482b5575))

## [1.18.0](https://github.com/nvim-java/nvim-java/compare/v1.17.0...v1.18.0) (2024-07-14)


### Features

* add warning on not yet implemented client commands ([a889ff4](https://github.com/nvim-java/nvim-java/commit/a889ff4ab49774849bd647d136370fa1b69c70f8))

## [1.17.0](https://github.com/nvim-java/nvim-java/compare/v1.16.0...v1.17.0) (2024-07-13)


### Features

* add generate constructor code action ([ea5371b](https://github.com/nvim-java/nvim-java/commit/ea5371bf0de96dd6856ae623455376d6e2062045))

## [1.16.0](https://github.com/nvim-java/nvim-java/compare/v1.15.0...v1.16.0) (2024-07-13)


### Features

* add convert to variable refactor command ([2635a64](https://github.com/nvim-java/nvim-java/commit/2635a640aebd007b52a3d288b1318cacca7dc44c))

## [1.15.0](https://github.com/nvim-java/nvim-java/compare/v1.14.0...v1.15.0) (2024-07-12)


### Features

* add extract_field command ([aabca01](https://github.com/nvim-java/nvim-java/commit/aabca011b56b605f7bf12df0534f7d5b60b16fff))

## [1.14.0](https://github.com/nvim-java/nvim-java/compare/v1.13.0...v1.14.0) (2024-07-11)


### Features

* upgrade java debug adapter ([644c4cb](https://github.com/nvim-java/nvim-java/commit/644c4cbe7cda5d7bac08f7ec293e08078d4afac0))

## [1.13.0](https://github.com/nvim-java/nvim-java/compare/v1.12.0...v1.13.0) (2024-07-10)


### Features

* add more extract commands ([0ec0f46](https://github.com/nvim-java/nvim-java/commit/0ec0f463efa7b3cc77d30660ced357e295ab7cd7))

## [1.12.0](https://github.com/nvim-java/nvim-java/compare/v1.11.0...v1.12.0) (2024-07-10)


### Features

* add command to change the runtime ([#244](https://github.com/nvim-java/nvim-java/issues/244)) ([af9c8ff](https://github.com/nvim-java/nvim-java/commit/af9c8ff3c7cf313611daa194409cb65e7831e98a))


### Bug Fixes

* remove github token from stylua workflow ([a6b1c8b](https://github.com/nvim-java/nvim-java/commit/a6b1c8b8a5569476c1a73bcb606ba2e33025d54e))
* the manually stoped/restarted job show the error message ([#242](https://github.com/nvim-java/nvim-java/issues/242)) ([#243](https://github.com/nvim-java/nvim-java/issues/243)) ([0b9fac9](https://github.com/nvim-java/nvim-java/commit/0b9fac9cae5ac13590d5e8201d9611aebbbece73))

## [1.11.0](https://github.com/nvim-java/nvim-java/compare/v1.10.0...v1.11.0) (2024-07-06)


### Features

* add build workspace command ([4d92c3d](https://github.com/nvim-java/nvim-java/commit/4d92c3d8552aa3c80a3f4a98754e570a564addf5))

## [1.10.0](https://github.com/nvim-java/nvim-java/compare/v1.9.1...v1.10.0) (2024-07-05)


### Features

* add spring boot tools support ([#232](https://github.com/nvim-java/nvim-java/issues/232)) ([028e870](https://github.com/nvim-java/nvim-java/commit/028e870c5a69cf5ee68e4776e9614a664cc65871))

## [1.9.1](https://github.com/nvim-java/nvim-java/compare/v1.9.0...v1.9.1) (2024-07-05)


### Bug Fixes

* get_client func is failing on older neovim ([bb7d586](https://github.com/nvim-java/nvim-java/commit/bb7d586161bf3e10153dc6a1180984d310c025fe))

## [1.9.0](https://github.com/nvim-java/nvim-java/compare/v1.8.0...v1.9.0) (2024-07-03)


### Features

* add mason registry check ([#225](https://github.com/nvim-java/nvim-java/issues/225)) ([ef7597d](https://github.com/nvim-java/nvim-java/commit/ef7597d158f0687c8c0bd2c11e5907c32e52574f))

## [1.8.0](https://github.com/nvim-java/nvim-java/compare/v1.7.0...v1.8.0) (2024-07-01)


### Features

* add validations for exec order, duplicate setup calls ([#219](https://github.com/nvim-java/nvim-java/issues/219)) ([15bc822](https://github.com/nvim-java/nvim-java/commit/15bc822acb1e11983bde70f436dd17d41ba76925))

## [1.7.0](https://github.com/nvim-java/nvim-java/compare/v1.6.1...v1.7.0) (2024-06-28)


### Features

* add lazy.lua file to declare dependencies on lazy.nvim ([#215](https://github.com/nvim-java/nvim-java/issues/215)) ([1349ac5](https://github.com/nvim-java/nvim-java/commit/1349ac545feb37459a04a0a37d41496463c63c87))

## [1.6.1](https://github.com/nvim-java/nvim-java/compare/v1.6.0...v1.6.1) (2024-06-27)


### Bug Fixes

* when the same main class is ran again, first process is not stopped ([1fae8de](https://github.com/nvim-java/nvim-java/commit/1fae8de1327167ac4b9f744970b2b6b7c7652874))

## [1.6.0](https://github.com/nvim-java/nvim-java/compare/v1.5.1...v1.6.0) (2024-06-25)


### Features

* handle multiple running app ([#182](https://github.com/nvim-java/nvim-java/issues/182)) ([#191](https://github.com/nvim-java/nvim-java/issues/191)) ([ca5cfdb](https://github.com/nvim-java/nvim-java/commit/ca5cfdba0d0629a829d16fa838808be0d5db8baa))

## [1.5.1](https://github.com/nvim-java/nvim-java/compare/v1.5.0...v1.5.1) (2024-05-29)


### Bug Fixes

* some dap warnings are not respecting notification rules ([#197](https://github.com/nvim-java/nvim-java/issues/197)) ([603f270](https://github.com/nvim-java/nvim-java/commit/603f2708cb2d3980f3787a2d9cfd10775e8f2606))

## [1.5.0](https://github.com/nvim-java/nvim-java/compare/v1.4.0...v1.5.0) (2024-05-05)


### Features

* allow extract variable command in visual mode ([0ac2e2f](https://github.com/nvim-java/nvim-java/commit/0ac2e2f5d8a4dc72b2fd249424534cd94d2c7a78))

## [1.4.0](https://github.com/nvim-java/nvim-java/compare/v1.3.1...v1.4.0) (2024-05-03)


### Features

* add extract variable refactor command ([#171](https://github.com/nvim-java/nvim-java/issues/171)) ([0e61713](https://github.com/nvim-java/nvim-java/commit/0e617134db2b540e5cee54856d8805e647f1d42f))

## [1.3.1](https://github.com/nvim-java/nvim-java/compare/v1.3.0...v1.3.1) (2024-04-12)


### Bug Fixes

* check existance of profile before modifications ([6c4f1e2](https://github.com/nvim-java/nvim-java/commit/6c4f1e2de5adb9e521947b95eb2ae32d03c61d0a))

## [1.3.0](https://github.com/nvim-java/nvim-java/compare/v1.2.0...v1.3.0) (2024-04-12)


### Features

* run/debug profiles ([#110](https://github.com/nvim-java/nvim-java/issues/110), [#131](https://github.com/nvim-java/nvim-java/issues/131)) ([#146](https://github.com/nvim-java/nvim-java/issues/146)) ([3442006](https://github.com/nvim-java/nvim-java/commit/3442006df0bbfb7fc5a45618d1fe971ce95a97a7))


### Bug Fixes

* profile deletion does not work ([#158](https://github.com/nvim-java/nvim-java/issues/158)) ([cb62d07](https://github.com/nvim-java/nvim-java/commit/cb62d076edf5c12f036cb55c121c2fa77becb0f4))
* typo in java profile ui command ([#156](https://github.com/nvim-java/nvim-java/issues/156)) ([30966b7](https://github.com/nvim-java/nvim-java/commit/30966b7314ffb01acc2886c24ef155bea9a1aaf1))

## [1.2.0](https://github.com/nvim-java/nvim-java/compare/v1.1.0...v1.2.0) (2024-03-23)


### Features

* **conf:** capability to remove dap related notifications ([9f9b785](https://github.com/nvim-java/nvim-java/commit/9f9b785e9f8a452e7bd56d809578efc1c5908b6b))


### Bug Fixes

* jdtls wont start up after new mason versioned package ([#147](https://github.com/nvim-java/nvim-java/issues/147)) ([8945fc1](https://github.com/nvim-java/nvim-java/commit/8945fc16452e9c6748194ac5e24379a8ccdcf3a2))
* **test:** tests are hanging after vim.ui.select to handle async ui change. ([#139](https://github.com/nvim-java/nvim-java/issues/139)) ([#140](https://github.com/nvim-java/nvim-java/issues/140)) ([ba1146e](https://github.com/nvim-java/nvim-java/commit/ba1146ebe859dbd2ea4fded68bb8b04805a894ec))

## [1.1.0](https://github.com/nvim-java/nvim-java/compare/v1.0.6...v1.1.0) (2024-03-17)


### Features

* APIs to run application ([#136](https://github.com/nvim-java/nvim-java/issues/136)) ([a0c6c1b](https://github.com/nvim-java/nvim-java/commit/a0c6c1b7dbf547b88350d6ffd033c61451a067eb))

## [1.0.6](https://github.com/nvim-java/nvim-java/compare/v1.0.5...v1.0.6) (2024-03-03)


### Bug Fixes

* lombok APIs with parameters are not working ([#129](https://github.com/nvim-java/nvim-java/issues/129)) ([5133a21](https://github.com/nvim-java/nvim-java/commit/5133a21ffc6b9545d9785721d34a212120a22749))

## [1.0.5](https://github.com/nvim-java/nvim-java/compare/v1.0.4...v1.0.5) (2024-03-01)


### Bug Fixes

* sometimes dap is not configured correctly ([#126](https://github.com/nvim-java/nvim-java/issues/126)) ([4f1f310](https://github.com/nvim-java/nvim-java/commit/4f1f31094632342cc45902276d11971507c415e0))

## [1.0.4](https://github.com/nvim-java/nvim-java/compare/v1.0.3...v1.0.4) (2024-01-13)


### Miscellaneous Chores

* release 1.0.4 ([a268bdd](https://github.com/nvim-java/nvim-java/commit/a268bddafec62282d1e7e5ad85d34696bf5dd027))

## [1.0.3](https://github.com/nvim-java/nvim-java/compare/v1.0.2...v1.0.3) (2024-01-07)


### Bug Fixes

* java-debug fails due to unavailablity of v0.52.0 ([#105](https://github.com/nvim-java/nvim-java/issues/105)) ([f20e49f](https://github.com/nvim-java/nvim-java/commit/f20e49fbfa84a73f371ba9bd925d19c57f0cdd70))

## [1.0.2](https://github.com/nvim-java/nvim-java/compare/v1.0.1...v1.0.2) (2023-12-17)


### Bug Fixes

* user jdtls setup config wont override the default config ([#91](https://github.com/nvim-java/nvim-java/issues/91)) ([fa14d06](https://github.com/nvim-java/nvim-java/commit/fa14d065d3e5d7402d8bde6ebb2099dfc9f29e3f))

## [1.0.1](https://github.com/nvim-java/nvim-java/compare/v1.0.0...v1.0.1) (2023-12-13)


### Bug Fixes

* goto definition error out due to buffer is not modifiable ([#74](https://github.com/nvim-java/nvim-java/issues/74)) ([d1233cc](https://github.com/nvim-java/nvim-java/commit/d1233ccc101866bcbea394c51b7c0780bf98bb9d))

## 1.0.0 (2023-12-10)


### ⚠ BREAKING CHANGES

* go from promises to co-routines ([#30](https://github.com/nvim-java/nvim-java/issues/30))
* change the project structure according to new core changes ([#27](https://github.com/nvim-java/nvim-java/issues/27))

### Features

* add API to open test reports ([#35](https://github.com/nvim-java/nvim-java/issues/35)) ([1fb58a6](https://github.com/nvim-java/nvim-java/commit/1fb58a6f0fb20253de3542a4ea950f435378ed30))
* add capability to lsp actions in .class files ([#11](https://github.com/nvim-java/nvim-java/issues/11)) ([8695b99](https://github.com/nvim-java/nvim-java/commit/8695b9972a40ee5eec2e4a05208db29db56b8a90))
* add commands for lua APIs ([#43](https://github.com/nvim-java/nvim-java/issues/43)) ([62bf7f7](https://github.com/nvim-java/nvim-java/commit/62bf7f79ed37ebf02b2ad1c670cc495105d025ad))
* add config option to install jdk17 via mason ([29e6318](https://github.com/nvim-java/nvim-java/commit/29e631803903b52eb070ec7f069db8a44081d925))
* add editor config ([01a6c15](https://github.com/nvim-java/nvim-java/commit/01a6c1534e80c7cfbdde58e5e4962cbf32e5cd80))
* add lint & release-please workflows ([#67](https://github.com/nvim-java/nvim-java/issues/67)) ([0751359](https://github.com/nvim-java/nvim-java/commit/0751359c08e6305ec031790f0c1fdb1091b3e03b))
* add plugin manager for testing ([1feb82e](https://github.com/nvim-java/nvim-java/commit/1feb82e5576b468f7e0ab7c87c6f19c8db7800aa))
* add test current method API ([#31](https://github.com/nvim-java/nvim-java/issues/31)) ([a5e5adb](https://github.com/nvim-java/nvim-java/commit/a5e5adb60a726ece9298723bd2c2e6000efc3731))
* auto configure jdtls and dap at start up ([#2](https://github.com/nvim-java/nvim-java/issues/2)) ([83e25bb](https://github.com/nvim-java/nvim-java/commit/83e25bb827aee6b52b389f608eca01a01fa7ee2a))
* auto refresh the mason registory when pkgs are not available ([#41](https://github.com/nvim-java/nvim-java/issues/41)) ([0edb02c](https://github.com/nvim-java/nvim-java/commit/0edb02c12ca5b8750f9734562d7ea2213e3c8442))
* Create FUNDING.yml ([f23b56e](https://github.com/nvim-java/nvim-java/commit/f23b56e3fc80156781e7d3029c365be766e3af24))
* extract debug & run APIs for current test class ([#14](https://github.com/nvim-java/nvim-java/issues/14)) ([b5368b2](https://github.com/nvim-java/nvim-java/commit/b5368b20fb2479e0571675d1646cce248e5a809b))
* **ui:** add visual indication for dap configuration status ([#60](https://github.com/nvim-java/nvim-java/issues/60)) ([7f5475e](https://github.com/nvim-java/nvim-java/commit/7f5475ebac07b7522afc24b2d6ff6afe5e1d373d))


### Bug Fixes

* 0.40.1 failure on install ([f16b08b](https://github.com/nvim-java/nvim-java/commit/f16b08b277400c1965679be6f5178cb5d04b6f25))
* build badge ([0af982e](https://github.com/nvim-java/nvim-java/commit/0af982e895e3eabfcae97d922eac733a758d5757))
* build shields badge ([db7b333](https://github.com/nvim-java/nvim-java/commit/db7b3335dfc1a38181b1702449aae50589382ae8))
* **ci:** invalid vim-doc name ([#16](https://github.com/nvim-java/nvim-java/issues/16)) ([4a64bb6](https://github.com/nvim-java/nvim-java/commit/4a64bb6eef90c857913780bbde92ad7411002eef))
* error in error handler function ([#24](https://github.com/nvim-java/nvim-java/issues/24)) ([2fd3979](https://github.com/nvim-java/nvim-java/commit/2fd39790df73669e2384f3dd1acd3c1322203dfb))
* error when java.setup with no table ([#56](https://github.com/nvim-java/nvim-java/issues/56)) ([18bb0ab](https://github.com/nvim-java/nvim-java/commit/18bb0abe4450bc7405f78f0d8e37f9787315102c))
* jdk auto_install should be true by default ([#59](https://github.com/nvim-java/nvim-java/issues/59)) ([2c82759](https://github.com/nvim-java/nvim-java/commit/2c827599f099d8b80cfdd74690ff807309748930))
* server module was moved from prev location in java-core ([#22](https://github.com/nvim-java/nvim-java/issues/22)) ([a27c215](https://github.com/nvim-java/nvim-java/commit/a27c2159c7ef5620137916419ed689501c6264ae))
* when launched first time lazy covers mason nvim window ([#52](https://github.com/nvim-java/nvim-java/issues/52)) ([340cad5](https://github.com/nvim-java/nvim-java/commit/340cad58b382b9e3f310fbc50427691f5b46af2f))


### Code Refactoring

* change the project structure according to new core changes ([#27](https://github.com/nvim-java/nvim-java/issues/27)) ([7c7b772](https://github.com/nvim-java/nvim-java/commit/7c7b772151b67bea7eb3bd96f78cfa337d106d8d))
* go from promises to co-routines ([#30](https://github.com/nvim-java/nvim-java/issues/30)) ([737792d](https://github.com/nvim-java/nvim-java/commit/737792d2595a01d0e3c491dcae907a7041d27c1b))
