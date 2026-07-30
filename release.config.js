// SPDX-FileCopyrightText: 2025 Deutsche Telekom AG
//
// SPDX-License-Identifier: Apache-2.0

module.exports = {
  // `main` publishes stable versions; `next` publishes `-rc.N` prereleases on the
  // `next` distribution channel. Both are protected release branches, and a push to
  // either one may publish automatically.
  branches: [
    { name: 'main', channel: false },
    { name: 'next', prerelease: 'rc', channel: 'next' },
  ],
  tagFormat: '${version}',
  plugins: [
    [
      '@semantic-release/commit-analyzer',
      {
        releaseRules: [
          { type: 'build', release: 'patch' },
          { type: 'chore', release: 'patch' },
          { type: 'ci', release: 'patch' },
          { type: 'docs', release: 'patch' },
          { type: 'perf', release: 'patch' },
          { type: 'refactor', release: 'patch' },
          { type: 'revert', release: 'patch' },
          { type: 'style', release: 'patch' },
          { type: 'test', release: 'patch' },
        ]
      }
    ],
    [
      '@semantic-release/release-notes-generator',
      {
        preset: 'conventionalcommits',
        presetConfig: {
          types: [
            { type: 'feat', section: 'Features', hidden: false },
            { type: 'fix', section: 'Bug Fixes', hidden: false },
            { type: 'build', section: 'Build System', hidden: false },
            { type: 'chore', section: 'Chores', hidden: false },
            { type: 'ci', section: 'Continuous Integration', hidden: false },
            { type: 'docs', section: 'Documentation', hidden: false },
            { type: 'perf', section: 'Performance Improvements', hidden: false },
            { type: 'refactor', section: 'Code Refactoring', hidden: false },
            { type: 'revert', section: 'Reverts', hidden: false },
            { type: 'style', section: 'Styles', hidden: false },
            { type: 'test', section: 'Tests', hidden: false },
          ]
        }
      }
    ],
    [
      // The chart version lives in Chart.yaml as well as in the Git tag, so it has to be
      // written into the working tree before @semantic-release/git commits it.
      '@semantic-release/exec',
      {
        prepareCmd: "awk -i inplace '{ gsub(/^version:.*/, \"version: ${nextRelease.version}\") }; { print }' Chart.yaml"
      }
    ],
    [
      '@semantic-release/git',
      {
        assets: ['Chart.yaml'],
        // `[skip release]` is recognised by semantic-release core and filters commits
        // carrying it out of commit analysis.
        //
        // Deliberately not `[skip ci]`, which @semantic-release/git would otherwise add
        // by default: downstream consumers mirror this repository and build their own
        // images from source, and they need this commit to trigger their CI.
        message: 'chore(release): ${nextRelease.version}\n\n[skip release]\n\n${nextRelease.notes}'
      }
    ],
    '@semantic-release/github'
  ],
};
