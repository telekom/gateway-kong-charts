// SPDX-FileCopyrightText: 2023 Deutsche Telekom AG
//
// SPDX-License-Identifier: Apache-2.0

module.exports = {
  branches: ['main'],
  tagFormat: '${version}',
  plugins: [
    '@semantic-release/commit-analyzer',
    '@semantic-release/release-notes-generator',
    [
      '@semantic-release/changelog',
      {
        changelogFile: 'CHANGELOG.md',
        changelogTitle: '# Changelog\n\nPlease refer to the README for additional upgrade instructions.\n',
      }
    ],
    [
      '@semantic-release/exec',
      {
        prepareCmd: "awk -i inplace '{ gsub(/^version:.*/, \"version: ${nextRelease.version}\") }; { print }' Chart.yaml"
      }
    ],
    [
      '@semantic-release/git',
      {
        assets: ['Chart.yaml', 'CHANGELOG.md'],
        message: 'chore(release): ${nextRelease.version} [skip ci]\n\n${nextRelease.notes}'
      }
    ],
    '@semantic-release/github'
  ]
};
