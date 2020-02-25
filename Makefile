src = src

# Generate list of available output templates
templates  = $(wildcard $(src)/template/*.mustache)
templates := $(notdir $(basename $(templates)))
templates := $(filter-out %.js,$(templates))

# Generate list of all templated targets
palettes = $(shell find $(src)/palettes -type f -name '*.js')
targets  = $(foreach t,$(templates),$(palettes:.js=.$(t)))
targets := $(targets:index.scss=_index.scss)
targets := $(targets:$(src)/palettes/%=%)

# Generate list of all index.js and index.json targets
palette-dirs = $(shell find $(src)/palettes -maxdepth 1 -mindepth 1 -type d)
targets += $(foreach p,$(notdir $(palette-dirs)),$(p)/index.js)
targets += $(targets:.js=.json)

# Output recipe template
define tpl-recipe=
%.$(1): %.js $(src)/template/$(1).mustache $(src)/view.js
	$$(render)
endef

# Template render command
define render=
	@mkdir -p $(@D)
	$(src)/render.sh $^ > $@
endef

all: $(targets)

clean:
	rm -rf $(targets)

index.js: $(src)/view.js $(src)/template/index.js.mustache
	npx mustache $^ > $@

# Special handling of _index.scss files
%/_index.scss: \
	%/index.js \
	$(src)/template/scss.mustache \
	$(src)/view.js
	$(render)

%/index.json: %/index.js
	@mkdir -p $(@D)
	node -p 'JSON.stringify(require("./$^"), null, 2)' > $@

%/index.js: $(src)/palettes/%/index.js
	@mkdir -p $(@D)
	cp $^ $@

# Auto-generate output recipes
$(foreach t,$(templates),$(eval $(call tpl-recipe,$(t))))

print-%:
	@echo "$* = $($*)"

.PHONY: all clean
