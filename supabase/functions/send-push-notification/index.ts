// Supabase Edge Function to send push notifications via Firebase Cloud Messaging V1 API
// This function is triggered when notifications need to be sent to users

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.0'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface NotificationPayload {
  user_ids?: string[] // Specific user IDs to send to
  all_users?: boolean // Send to all users
  title: string
  body: string
  data?: Record<string, string> // Additional data payload
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Get Firebase Service Account JSON from environment variables
    const FIREBASE_SERVICE_ACCOUNT = Deno.env.get('FIREBASE_SERVICE_ACCOUNT')
    if (!FIREBASE_SERVICE_ACCOUNT) {
      throw new Error('FIREBASE_SERVICE_ACCOUNT not configured')
    }
    
    const serviceAccount = JSON.parse(FIREBASE_SERVICE_ACCOUNT)
    const projectId = serviceAccount.project_id

    // Parse request body
    const payload: NotificationPayload = await req.json()
    const { user_ids, all_users, title, body, data } = payload

    // Initialize Supabase client
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    // Get FCM tokens for target users
    let tokens: string[] = []
    
    if (all_users) {
      // Get all user tokens
      const { data: users, error } = await supabase
        .from('gebruikers')
        .select('fcm_token')
        .not('fcm_token', 'is', null)
      
      if (error) throw error
      tokens = users.map(u => u.fcm_token).filter(Boolean)
    } else if (user_ids && user_ids.length > 0) {
      // Get specific user tokens
      const { data: users, error } = await supabase
        .from('gebruikers')
        .select('fcm_token')
        .in('gebr_id', user_ids)
        .not('fcm_token', 'is', null)
      
      if (error) throw error
      tokens = users.map(u => u.fcm_token).filter(Boolean)
    } else {
      throw new Error('Either user_ids or all_users must be specified')
    }

    if (tokens.length === 0) {
      return new Response(
        JSON.stringify({ 
          success: true, 
          message: 'No tokens found to send to',
          sent: 0 
        }),
        { 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 200 
        }
      )
    }

    // Get OAuth access token for V1 API
    const accessToken = await getAccessToken(serviceAccount)

    // Send push notifications via FCM V1 API
    const results = await Promise.allSettled(
      tokens.map(token => sendFCMNotification(token, title, body, data, accessToken, projectId))
    )

    const successful = results.filter(r => r.status === 'fulfilled').length
    const failed = results.filter(r => r.status === 'rejected').length

    // Clean up invalid tokens
    const failedTokens = results
      .map((r, i) => r.status === 'rejected' ? tokens[i] : null)
      .filter(Boolean)
    
    if (failedTokens.length > 0) {
      // Remove invalid tokens from database
      await supabase
        .from('gebruikers')
        .update({ fcm_token: null })
        .in('fcm_token', failedTokens)
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: `Sent ${successful} notifications, ${failed} failed`,
        sent: successful,
        failed: failed,
        total: tokens.length,
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    )
  } catch (error) {
    console.error('Error sending push notifications:', error)
    return new Response(
      JSON.stringify({
        success: false,
        error: error.message,
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 400,
      }
    )
  }
})

// Get OAuth 2.0 access token for FCM V1 API
async function getAccessToken(serviceAccount: any): Promise<string> {
  const SCOPES = ['https://www.googleapis.com/auth/firebase.messaging']
  
  // Create JWT
  const header = {
    alg: 'RS256',
    typ: 'JWT',
  }
  
  const now = Math.floor(Date.now() / 1000)
  const claim = {
    iss: serviceAccount.client_email,
    scope: SCOPES.join(' '),
    aud: 'https://oauth2.googleapis.com/token',
    exp: now + 3600,
    iat: now,
  }
  
  // Encode header and claim
  const encodedHeader = btoa(JSON.stringify(header)).replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_')
  const encodedClaim = btoa(JSON.stringify(claim)).replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_')
  const signatureInput = `${encodedHeader}.${encodedClaim}`
  
  // Import private key and sign
  const privateKey = await crypto.subtle.importKey(
    'pkcs8',
    pemToArrayBuffer(serviceAccount.private_key),
    {
      name: 'RSASSA-PKCS1-v1_5',
      hash: 'SHA-256',
    },
    false,
    ['sign']
  )
  
  const signature = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    privateKey,
    new TextEncoder().encode(signatureInput)
  )
  
  const encodedSignature = btoa(String.fromCharCode(...new Uint8Array(signature)))
    .replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_')
  
  const jwt = `${signatureInput}.${encodedSignature}`
  
  // Exchange JWT for access token
  const tokenResponse = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  })
  
  if (!tokenResponse.ok) {
    throw new Error(`Failed to get access token: ${await tokenResponse.text()}`)
  }
  
  const tokenData = await tokenResponse.json()
  return tokenData.access_token
}

// Convert PEM private key to ArrayBuffer
function pemToArrayBuffer(pem: string): ArrayBuffer {
  const b64 = pem
    .replace(/-----BEGIN PRIVATE KEY-----/, '')
    .replace(/-----END PRIVATE KEY-----/, '')
    .replace(/\s/g, '')
  
  const binary = atob(b64)
  const bytes = new Uint8Array(binary.length)
  for (let i = 0; i < binary.length; i++) {
    bytes[i] = binary.charCodeAt(i)
  }
  return bytes.buffer
}

// Send notification to a single FCM token using V1 API
async function sendFCMNotification(
  token: string,
  title: string,
  body: string,
  data: Record<string, string> | undefined,
  accessToken: string,
  projectId: string
): Promise<void> {
  const fcmPayload = {
    message: {
      token: token,
      notification: {
        title,
        body,
      },
      data: data || {},
      android: {
        priority: 'high',
        notification: {
          sound: 'default',
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
          },
        },
      },
    },
  }

  const response = await fetch(
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
    {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${accessToken}`,
      },
      body: JSON.stringify(fcmPayload),
    }
  )

  if (!response.ok) {
    const error = await response.text()
    throw new Error(`FCM V1 request failed: ${error}`)
  }

  await response.json()
}

