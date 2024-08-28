OBJ_VERSION=$(shell grep -Eo 'obj.version\s*=\s*"[^"]+"' init.lua | cut -d'"' -f2)
SHORT_GIT_SHA=$(shell git rev-parse --short HEAD)
BASE_TAG=v$(OBJ_VERSION)
TAG_FILE=.tag

# Ensure auto-changelog is installed
install_auto_changelog:
	@if ! command -v auto-changelog &> /dev/null; then \
        echo "auto-changelog not found. Installing..."; \
        npm install -g auto-changelog; \
    fi

# Release target
release: install_auto_changelog clean_changelog check_tag_exists create_tag generate_changelog push_tag

# Clean the old changelog file
clean_changelog:
	@echo "Cleaning old CHANGELOG.md"
	@rm -f CHANGELOG.md

# Check if the base tag exists, and update TAG if necessary
check_tag_exists:
	@if git rev-parse "$(BASE_TAG)" >/dev/null 2>&1; then \
        echo "Tag $(BASE_TAG) already exists, updating tag to include SHA"; \
        echo "$(BASE_TAG)-$(SHORT_GIT_SHA)" > $(TAG_FILE); \
	else \
        echo "Creating new tag $(BASE_TAG)"; \
        echo "$(BASE_TAG)" > $(TAG_FILE); \
	fi

# Create a git tag with the updated TAG
create_tag:
	@TAG=$$(cat $(TAG_FILE)); \
	git tag -a $$TAG -m "Release $$TAG"; \
	echo "Tag created: $$TAG"

# Generate a changelog using auto-changelog
generate_changelog:
	@echo "Generating CHANGELOG.md"
	@auto-changelog --tag-prefix "v" --output CHANGELOG.md
	@echo "Changelog generated."
	@git add CHANGELOG.md
	@if ! git diff --cached --quiet; then \
        git commit -m "Update CHANGELOG.md for release $(BASE_TAG)"; \
    else \
        echo "No changes to commit for the changelog."; \
    fi

# Push the code and tag
push_tag:
	@TAG=$$(cat $(TAG_FILE)); \
	git push origin main; \
	git push origin $$TAG; \
	echo "Code and tag pushed to GitHub: $$TAG"

# Clean up the temporary tag file
clean:
	@rm -f $(TAG_FILE)
