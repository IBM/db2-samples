# Maintainers Guide

This guide is intended for maintainers - anybody with commit access to this repository.

## Methodology

This repository does not have a traditional release management cycle, but should instead be maintained as a useful, working, and polished reference at all times. While all work can therefore be focused on the master branch, the quality of this branch should never be compromised.

The remainder of this document details how to merge pull requests to the repositories.

## Merge approval

The project Maintainers use reviews within GitHub on the pull request to indicate acceptance prior to merging.  Pull requests will not be merged until they have been reviewed and signed-off by at least one Maintainer.  If the code is written by a Maintainer, the change requires one additional review sign-off.

## Reviewing Pull Requests

We require review of pull requests directly within GitHub. This allows a public commentary on changes, providing transparency for all users. When providing feedback be civil, courteous, and kind. Disagreement is fine, so long as the discourse is carried out politely. A record of uncivil or abusive comments is not welcome.

During your review, consider the following points:

### Does the change have positive impact?

Some proposed changes may not represent a positive impact to the project. Ask yourself whether or not the change will make understanding or using the product easier, or if it could simply be a personal preference on the part of the author (see [bikeshedding](https://en.wiktionary.org/wiki/bikeshedding)).

Pull requests that do not have a clear positive impact should be closed without merging.

### Do the changes make sense?

If you do not understand what the changes are or what they accomplish, ask the author for clarification. Ask the author to add comments and/or to clarify naming to make the intentions clear.

At times, such clarification will reveal that the author may not be using the code correctly, or is unaware of features that may already accommodate their needs.

### Does the change introduce a new feature or sample?

For any given pull request, ask yourself "is this a new example?" If so, does the pull request (or associated issue) contain a sufficient narrative indicating the need and use-case for the example? If not, ask them to provide that information.  Also:

- Is the example portable to all of the intended and supported Db2 family platforms?
- Is documentation in place for the new feature?  For example, updates to both local (to the containing directory) and global README's.  If not, do not merge the feature until it is!
- Is the change necessary for general use cases? Try and keep the scope of any given sample as narrow and simple as appropriate. If a proposed change or new example does not fit that scope, recommend to the author that consider refactoring it, perhaps into a new sample.
