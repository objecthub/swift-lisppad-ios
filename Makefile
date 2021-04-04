.PHONY: clean update

all: update

update:
	carthage update --platform iOS --use-xcframeworks

clean:
	rm -rf .build
