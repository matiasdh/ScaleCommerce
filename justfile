# justfile - Command runner for ScaleCommerce
# Install: brew install just
# Usage: just <recipe>

# Default recipe - show available commands
default:
    @just --list

# === Development ===

# Start infra (postgres + redis) and Rails server
start: infra
    bin/rails server

# Start only infrastructure (postgres + redis)
infra:
    docker-compose up -d postgres redis
    @echo "Waiting for services..."
    @sleep 2
    @docker-compose ps

# Stop all Docker services
down:
    docker-compose down

# View Docker logs
logs:
    docker-compose logs -f

# === Database ===

# Setup database (create + migrate + seed)
db-setup: infra
    bin/rails db:create db:migrate db:seed

# Run migrations
db-migrate:
    bin/rails db:migrate

# Reset database
db-reset:
    bin/rails db:reset

# === Testing ===

# Run all tests
test:
    rspec

# Run specific test file
test-file FILE:
    rspec {{FILE}}

# === Console & Tools ===

# Rails console
console:
    bin/rails console

# Redis CLI
redis-cli:
    docker-compose exec redis redis-cli

# Postgres CLI
psql:
    docker-compose exec postgres psql -U postgres -d scale_commerce_development
