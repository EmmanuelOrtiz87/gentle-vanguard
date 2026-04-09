name: Pull Request
description: Submit changes to the project
title: "[PR] "
labels: ["triage"]
assignees: []
body:
  - type: markdown
    attributes:
      value: |
        ## Pull Request
        
        Thank you for submitting a PR! Please fill out this template.
        
  - type: input
    id: pr-type
    attributes:
      label: PR Type
      description: What type of PR is this?
      placeholder: "e.g., feat/fix/docs/refactor/chore"
    validations:
      required: true

  - type: textarea
    id: description
    attributes:
      label: Description
      description: Describe your changes.
      placeholder: |
        ## Summary
        Brief description of changes.
        
        ## Type of Change
        - [ ] Bug fix
        - [ ] New feature
        - [ ] Breaking change
        - [ ] Documentation update
    validations:
      required: true

  - type: textarea
    id: motivation
    attributes:
      label: Motivation and Context
      description: Why is this change required? What problem does it solve?
      placeholder: |

  - type: textarea
    id: testing
    attributes:
      label: Testing
      description: How was this tested?
      placeholder: |
        - [ ] Unit tests added
        - [ ] Integration tests added
        - [ ] Manual testing performed
        - [ ] No tests needed

  - type: textarea
    id: checklist
    attributes:
      label: Checklist
      description: Make sure all items are checked
      placeholder: |
        - [ ] Code follows the project's style guidelines
        - [ ] Self-review completed
        - [ ] Comments added for complex code
        - [ ] Documentation updated
        - [ ] No console.log or debug code
        - [ ] No secrets committed
        - [ ] Commits follow conventional commits

  - type: input
    id: related
    attributes:
      label: Related Issues
      description: Link related issues (e.g., Closes #123)
      placeholder: "e.g., Closes #123, Related to #456"
