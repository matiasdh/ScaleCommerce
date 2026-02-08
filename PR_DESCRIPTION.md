# Add Status Enum to Orders

## Summary
Adds a `status` enum field to the `Order` model to track order lifecycle states.

## Changes
- **Migration**: Creates `order_status` enum type with 8 status values and adds `status` column to `orders` table (defaults to `"pending"`, not null)
- **Model**: Adds status enum to `Order` model with validation
- **Specs**: Updates model and service specs to test status enum behavior and verify orders are created with correct status

## Status Values
- `pending` (default)
- `authorized`
- `insufficient_funds`
- `captured`
- `partially_fulfilled`
- `fulfilled`
- `completed`
- `failed`

## Testing
- All enum values are validated
- Default status is `pending` for new orders
- Orders created through checkout service have `pending` status
- Invalid status values raise `ArgumentError`
