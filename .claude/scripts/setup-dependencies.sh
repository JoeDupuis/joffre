#!/bin/bash
set -e

echo "🔧 Setting up development environment..."

# Navigate to project directory
cd "$CLAUDE_PROJECT_DIR"

# Check Ruby version
REQUIRED_RUBY=$(cat .ruby-version | tr -d '[:space:]')
CURRENT_RUBY=$(ruby --version | awk '{print $2}' | cut -d'p' -f1)

echo "📦 Required Ruby version: $REQUIRED_RUBY"
echo "📦 Current Ruby version: $CURRENT_RUBY"

# Install Ruby version if using rbenv and version doesn't match
if command -v rbenv &> /dev/null; then
  if ! rbenv versions | grep -q "$REQUIRED_RUBY"; then
    echo ""
    echo "⚠️  WARNING: Ruby $REQUIRED_RUBY is not installed!"
    echo "⚠️  This will attempt to install it now, which may take several minutes."
    echo "⚠️  For faster startup, pre-install Ruby $REQUIRED_RUBY before starting Claude Code:"
    echo "    rbenv install $REQUIRED_RUBY"
    echo ""
    echo "📦 Installing Ruby $REQUIRED_RUBY..."
    rbenv install "$REQUIRED_RUBY" --skip-existing
    rbenv local "$REQUIRED_RUBY"
  else
    echo "✅ Ruby $REQUIRED_RUBY is available"
    rbenv local "$REQUIRED_RUBY"
  fi
fi

# Ensure bundler is installed
if ! gem list bundler -i &> /dev/null; then
  echo "📦 Installing bundler..."
  gem install bundler --no-document
else
  echo "✅ Bundler is already installed"
fi

# Install Ruby dependencies
echo "📦 Installing Ruby gems..."
bundle config set --local path 'vendor/bundle'
bundle install

echo "✅ All dependencies installed successfully!"
echo ""
echo "🧪 To run tests: bundle exec rails test"
echo "🔍 To run linter: bundle exec rubocop"
echo "🛡️  To run security scan: bundle exec brakeman"
