# Delete Supervisor Edge Function

This edge function deletes both the supervisor record from the `supervisors` table AND the associated user from `auth.users` using the service role key.

## Setup

The function requires the `SUPABASE_SERVICE_ROLE_KEY` environment variable. This is automatically available in deployed edge functions.

## Deployment

Deploy the function using the Supabase CLI:

```bash
supabase functions deploy delete_supervisor
```

## Testing Locally

1. Start Supabase locally:
```bash
supabase start
```

2. Serve the function:
```bash
supabase functions serve delete_supervisor
```

3. Test the function:
```bash
curl -i --location --request POST 'http://127.0.0.1:54321/functions/v1/delete_supervisor' \
  --header 'Authorization: Bearer YOUR_USER_TOKEN' \
  --header 'Content-Type: application/json' \
  --data '{"uid":"supervisor-uid-here"}'
```

## How it Works

1. Validates the request has proper authorization
2. Deletes the user from `auth.users` using admin API (with service role)
3. Returns success/error response
4. The frontend service then deletes the supervisor record from the database

