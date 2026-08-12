import { createClient } from '@supabase/supabase-js'

const supabaseUrl = process.env.SUPABASE_URL || 'https://dummy.supabase.co'
// We use the service role key for admin tasks like uploading avatars server-side
const supabaseServiceKey = process.env.SUPABASE_SERVICE_ROLE_KEY || 'dummy'

export const supabase = createClient(supabaseUrl, supabaseServiceKey, {
  auth: {
    autoRefreshToken: false,
    persistSession: false
  }
})
