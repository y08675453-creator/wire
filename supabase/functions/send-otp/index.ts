import { createClient } from 'npm:@supabase/supabase-js@2.75.0';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Client-Info, Apikey',
};

interface RequestBody {
  phoneNumber: string;
}

function normalizeIndianPhone(phone: string): string {
  let cleaned = phone.replace(/\D/g, '');
  
  if (cleaned.startsWith('0')) {
    cleaned = cleaned.substring(1);
  }
  
  if (cleaned.startsWith('91')) {
    return `+${cleaned}`;
  }
  
  if (cleaned.length === 10) {
    return `+91${cleaned}`;
  }
  
  if (phone.startsWith('+91')) {
    return phone;
  }
  
  return `+91${cleaned}`;
}

function isValidIndianPhone(phone: string): boolean {
  const cleaned = phone.replace(/\D/g, '');
  
  if (cleaned.length === 10) {
    return /^[6-9]\d{9}$/.test(cleaned);
  }
  
  if (cleaned.length === 12 && cleaned.startsWith('91')) {
    return /^91[6-9]\d{9}$/.test(cleaned);
  }
  
  return false;
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, {
      status: 200,
      headers: corsHeaders,
    });
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const twilioAccountSid = Deno.env.get('TWILIO_ACCOUNT_SID');
    const twilioAuthToken = Deno.env.get('TWILIO_AUTH_TOKEN');
    const twilioPhoneNumber = Deno.env.get('TWILIO_PHONE_NUMBER');

    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    const { phoneNumber }: RequestBody = await req.json();

    if (!phoneNumber) {
      return new Response(
        JSON.stringify({ success: false, message: 'Phone number is required' }),
        {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      );
    }

    if (!isValidIndianPhone(phoneNumber)) {
      return new Response(
        JSON.stringify({ success: false, message: 'Please enter a valid Indian phone number (10 digits starting with 6-9)' }),
        {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      );
    }

    const normalizedPhone = normalizeIndianPhone(phoneNumber);
    console.log(`Normalized phone: ${phoneNumber} -> ${normalizedPhone}`);

    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const expiresAt = new Date();
    expiresAt.setMinutes(expiresAt.getMinutes() + 5);

    const { error: dbError } = await supabase
      .from('otp_codes')
      .insert({
        phone_number: normalizedPhone,
        otp_code: otp,
        expires_at: expiresAt.toISOString(),
        verified: false,
      });

    if (dbError) {
      console.error('Database error:', dbError);
      return new Response(
        JSON.stringify({ success: false, message: 'Failed to save OTP' }),
        {
          status: 500,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      );
    }

    if (twilioAccountSid && twilioAuthToken && twilioPhoneNumber) {
      try {
        const twilioUrl = `https://api.twilio.com/2010-04-01/Accounts/${twilioAccountSid}/Messages.json`;
        const message = `Your WireBazaar OTP is: ${otp}. Valid for 5 minutes.`;

        const twilioResponse = await fetch(twilioUrl, {
          method: 'POST',
          headers: {
            'Authorization': 'Basic ' + btoa(`${twilioAccountSid}:${twilioAuthToken}`),
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          body: new URLSearchParams({
            To: normalizedPhone,
            From: twilioPhoneNumber,
            Body: message,
          }),
        });

        if (!twilioResponse.ok) {
          const errorData = await twilioResponse.text();
          console.error('Twilio error:', errorData);
          console.log(`OTP for ${normalizedPhone}: ${otp} (Twilio failed, showing in logs)`);
          
          return new Response(
            JSON.stringify({
              success: true,
              message: `OTP generated. Check console for code (SMS delivery failed).`,
              otp: otp,
            }),
            {
              status: 200,
              headers: { ...corsHeaders, 'Content-Type': 'application/json' },
            }
          );
        }

        return new Response(
          JSON.stringify({
            success: true,
            message: `OTP sent successfully to ${normalizedPhone}`,
          }),
          {
            status: 200,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          }
        );
      } catch (twilioError) {
        console.error('Twilio request error:', twilioError);
        console.log(`OTP for ${normalizedPhone}: ${otp} (Twilio failed, showing in logs)`);
        
        return new Response(
          JSON.stringify({
            success: true,
            message: `OTP generated. Check console for code.`,
            otp: otp,
          }),
          {
            status: 200,
            headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          }
        );
      }
    } else {
      console.log(`OTP for ${normalizedPhone}: ${otp} (Twilio not configured)`);
      
      return new Response(
        JSON.stringify({
          success: true,
          message: `OTP generated. Check console for code.`,
          otp: otp,
        }),
        {
          status: 200,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      );
    }
  } catch (error) {
    console.error('Error in send-otp:', error);
    return new Response(
      JSON.stringify({
        success: false,
        message: 'An error occurred while sending OTP',
      }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    );
  }
});