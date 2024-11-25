.PHONY: all test fix

all: fix test

# Run tests
test:
	bundle exec rake test

# Fix code formatting
fix:
	bundle exec standardrb --fix

# Install dependencies
install:
	bundle install

# Run both fix and test
check: fix test
