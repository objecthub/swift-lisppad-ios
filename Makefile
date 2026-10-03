.PHONY: clean update

all: update

update:
	carthage update --platform iOS --use-xcframeworks

select:
	sudo xcode-select -s /Applications/Xcode\ 27.1.app/Contents/Developer

clean:
	rm -rf .build
