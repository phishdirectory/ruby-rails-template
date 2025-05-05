# Template Repository

This is a fork of [ruby-rails-template](https://github.com/jaspermayone/ruby-rails-template) by @jaspermayone.

## Setup Guide

### Initial Repository Setup

1. **Create Your Repository**
   Click the "Use this template" button or fork this repository to get started.

2. **Configure GitHub Settings**

   - Import the ruleset: Copy `main-ruleset.yml` from the `.github` folder into your new repository.
   - Set up Dependabot: Rename `.github/dependabot.disabled.yml` to `.github/dependabot.yml` and update for your package ecosystem.
   - Update code ownership: Edit `.github/CODEOWNERS` with appropriate usernames or teams.

3. **Customize This README**
   - Change the title to your repository name
   - Add a project description
   - Include maintainer contact information

### Application Setup

1. Generate unique credentials:

   ```sh
   bin/regenerate-credentials
   ```

   This creates a secure master key and credentials file specific to your project.

2. Generate a Lockbox encryption key by running in the Rails console:

   ```ruby
   Lockbox.generate_key
   ```
   
3. Generate an ARE Key by running
    ```sh
    bin/rails db:encryption:init
    ```

4. Generate a blind_index key by running
   ```sh
   openssl rand -hex 32
   ```

5. Add the generated keys to your credentials:

   ```sh
   rails credentials:edit
   ```

   Then insert the keys in this format (replace the replaceme's with generated creds):

   ```yaml

    active_record_encryption:
      primary_key: REPLACEME
      deterministic_key: REPLACEME
      key_derivation_salt: REPLACEME

   lockbox:
     master_key: REPLACEME

   blind_index:
     master_key: REPLACEME
   ```

6. Replace all instances of "REPLACEMEWITHAPPNAME" with your actual application name.

7. Install dependencies:

   ```sh
   bundle install
   ```
   
### Next Steps

You're ready to start development! Consider reviewing:

- Database configuration in `config/database.yml`
- Environment variables in `.env.example` (copy to `.env` for local development)

---

## Example Readme

```markdown
# my-awesome-project

A simple tool to automate phishing domain detection.

Maintainer: @yourusername
Contact: you@example.com
```
