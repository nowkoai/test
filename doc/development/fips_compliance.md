---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
---

# FIPS compliance

FIPS is short for "Federal Information Processing Standard", a document which
defines certain security practices for a "cryptographic module" (CM). It aims
to ensure a certain security floor is met by vendors selling products to U.S.
Federal institutions.

WARNING:
GitLab is not FIPS compliant, even when built and run on a FIPS-enforcing
system. Large parts of the build are broken, and many features use forbidden
cryptographic primitives. Running GitLab on a FIPS-enforcing system is not
supported and may result in data loss. This document is intended to help
engineers looking to develop FIPS-related fixes. It is not intended to be used
to run a production GitLab instance.

There are two current FIPS standards: [140-2](https://en.wikipedia.org/wiki/FIPS_140-2)
and [140-3](https://en.wikipedia.org/wiki/FIPS_140-3). At GitLab we usually
mean FIPS 140-2.

## Current status

GitLab Inc has not committed to making GitLab FIPS-compliant at this time. We are
performing initial investigations to see how much work such an effort would be.

Read [Epic &5104](https://gitlab.com/groups/gitlab-org/-/epics/5104) for more
information on the status of the investigation.

## FIPS compliance at GitLab

In a FIPS context, compliance is a form of self-certification - if we say we are
"FIPS compliant", we mean that we *believe* we are. There are no external
certifications to acquire, but if we are aware of non-compliant areas
in GitLab, we cannot self-certify in good faith.

The known areas of non-compliance are tracked in [Epic &5104](https://gitlab.com/groups/gitlab-org/-/epics/5104).

To be compliant, all components (GitLab itself, Gitaly, etc) must be compliant,
along with the communication between those components, and any storage used by
them. Where functionality cannot be brought into compliance, it must be disabled
when FIPS mode is enabled.

## FIPS validation at GitLab

Unlike FIPS compliance, FIPS validation is a formal declaration of compliance by
an accredited auditor. The requirements needed to pass the audit are the same as
for FIPS compliance.

A list of FIPS-validated modules can be found at the
NIST (National Institute of Standards and Technology)
[cryptographic module validation program](https://csrc.nist.gov/projects/cryptographic-module-validation-program/validated-modules).

## Setting up a FIPS-enabled development environment

The simplest approach is to set up a virtual machine running
[Red Hat Enterprise Linux 8](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/security_hardening/using-the-system-wide-cryptographic-policies_security-hardening#switching-the-system-to-fips-mode_using-the-system-wide-cryptographic-policies).

Red Hat provide free licenses to developers, and permit the CD image to be
downloaded from the [Red Hat developer's portal](https://developers.redhat.com).
Registration is required.

After the virtual machine is set up, you can follow the [GDK](https://gitlab.com/gitlab-org/gitlab-development-kit)
installation instructions, including the [advanced instructions for RHEL](https://gitlab.com/gitlab-org/gitlab-development-kit/-/blob/main/doc/advanced.md#red-hat-enterprise-linux).
Note that `asdf` is not used for dependency management because it's essential to
use the RedHat-provided Go compiler and other system dependencies.

### Enable FIPS mode

After GDK and its dependencies are installed, run this command (as
root) and restart the virtual machine:

```shell
fips-mode-setup --enable
```

You can check whether it's taken effect by running:

```shell
fips-mode-setup --check
```

In this environment, OpenSSL refuses to perform cryptographic operations
forbidden by the FIPS standards. This enables you to reproduce FIPS-related bugs,
and validate fixes.

You should be able to open a web browser inside the virtual machine and log in
to the GitLab instance.

You can disable FIPS mode again by running this command, then restarting the
virtual machine:

```shell
fips-mode-setup --disable
```
