import { createClient } from '@supabase/supabase-js'

const url = import.meta.env.VITE_SUPABASE_URL as string | undefined
const anonKey = import.meta.env.VITE_SUPABASE_ANON_KEY as string | undefined

// Public anon key is intended for browser use only when RLS is correctly configured.
// Never expose the Supabase service-role key in this application.
export const supabase = url && anonKey ? createClient(url, anonKey) : null