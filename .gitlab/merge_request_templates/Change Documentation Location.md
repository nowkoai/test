<!--
  See the general Documentation guidelines https://docs.gitlab.com/ee/development/documentation/
  Use this description template for changing documentation location. For new documentation or
  updates to existing documentation, use the Documentation.md template.
-->

## What does this MR do?

<!-- Briefly describe what this MR is about -->

## Related issues

<!-- Link related issues below. -->

## Moving docs to a new location?

Read the guidelines:
https://docs.gitlab.com/ee/development/documentation/index.html#move-or-rename-a-page

- [ ] Make sure the old link is not removed and has its contents replaced with
      a link to the new location.
- [ ] Make sure internal links pointing to the document in question are not broken.
- [ ] Search and replace any links referring to old docs in GitLab Rails app,
      specifically under the `app/views/` and `ee/app/views` (for GitLab EE) directories.
- [ ] Make sure to add [`redirect_from`](https://docs.gitlab.com/ee/development/documentation/index.html#redirections-for-pages-with-disqus-comments)
      to the new document if there are any Disqus comments on the old document thread.
- [ ] Update the link in `features.yml` (if applicable).
- [ ] Assign one of the technical writers for review.

/label ~documentation ~"Technical Writing"
