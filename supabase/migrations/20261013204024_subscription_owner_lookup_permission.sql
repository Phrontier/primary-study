-- The invoker RPC checks whether the original purchase account still exists.
-- Grant only its identifier, never email addresses, passwords, or other Auth fields.
grant select (id) on auth.users to service_role;
