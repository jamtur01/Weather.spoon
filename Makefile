# Variables to track current version and short git SHA
OBJ_VERSION=$(shell grep -Eo 'obj.version\s*=\s*"[^"]+"' init.lua | cut -d'"' -f2)
SHORT_GIT_SHA=$(shell git rev-parse --short HEAD)
TAG_FILE=.tag

# Ensure auto-changelog is installed
install_auto_changelog:
	@if ! command -v auto-changelog &> /dev/null; then \
        echo "auto-changelog not found. Installing..."; \
        npm install -g auto-changelog; \
    fi

# Increment the version in init.lua
increment_version:
	@echo "Current version: $(OBJ_VERSION)"
	@new_version=$$(echo $(OBJ_VERSION) | awk -F. '{$$NF = $$NF + 1;} 1' | sed 's/ /./g'); \
	echo "Incrementing version to: $$new_version"; \
	sed -i.bak 's/obj.version = "$(OBJ_VERSION)"/obj.version = "$$new_version"/' init.lua; \
	echo "Version incremented to $$new_version"
	@echo "$$new_version" > $(TAG_FILE)
	@rm -f init.lua.bak

# Commit the version change
commit_version_change:
	@git add init.lua
	@git commit -m "Bump version to v$$(cat $(TAG_FILE))"

# Create a new tag based on the incremented version
create_tag:
	@new_version=$$(cat $(TAG_FILE)); \
	git tag -a "v$$new_version" -m "Release v$$new_version"
	@echo "Tag created: v$$new_version"

# Generate a changelog using auto-changelog
changelog:
	@echo "Generating CHANGELOG.md"
	@auto-changelog --tag-prefix "v" --output CHANGELOG.md
	@echo "Changelog generated."
	@git add CHANGELOG.md
	@git commit -m "Update CHANGELOG.md for release v$$(cat $(TAG_FILE))"

# Push the code and tag
push_tag:
	@git push origin main
	@git push origin $$(cat $(TAG_FILE))
	@echo "Code and tag pushed to GitHub: v$$(cat $(TAG_FILE))"

# Release target
release: install_auto_changelog increment_version commit_version_change create_tag changelog push_tag clean

# Clean up the temporary tag file
clean:
	@rm -f $(TAG_FILE)
