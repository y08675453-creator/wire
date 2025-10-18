# Twilio OTP Setup Guide

This application uses Twilio for sending OTP (One-Time Password) messages to users during phone authentication.

## How It Works

The OTP system is implemented through a Supabase Edge Function that:
1. Generates a 6-digit OTP code
2. Stores it in the database with a 5-minute expiration
3. Attempts to send it via Twilio SMS
4. Falls back to console logging if Twilio is not configured

## Current Behavior

**Without Twilio Configuration:**
- OTP codes are generated and stored in the database
- The OTP is displayed in the browser console for testing
- Users can still authenticate using the OTP shown in console
- This is perfect for development and testing

**With Twilio Configuration:**
- OTP codes are sent via SMS to the user's phone number
- Production-ready authentication flow
- More secure as OTP is not displayed anywhere

## Twilio Setup Instructions

To enable SMS-based OTP delivery, you need to configure Twilio environment variables in your Supabase project:

### 1. Get Twilio Credentials

1. Sign up for a Twilio account at https://www.twilio.com/try-twilio
2. Get your Account SID and Auth Token from the Twilio Console
3. Purchase a phone number or use the free trial number

### 2. Configure Supabase Environment Variables

You need to set these environment variables in your Supabase project:

```
TWILIO_ACCOUNT_SID=your_account_sid
TWILIO_AUTH_TOKEN=your_auth_token
TWILIO_PHONE_NUMBER=your_twilio_phone_number
```

### 3. How to Set Environment Variables

**Using Supabase Dashboard:**
1. Go to your Supabase project dashboard
2. Navigate to Settings > Edge Functions
3. Add the three environment variables listed above

**Using Supabase CLI:**
```bash
supabase secrets set TWILIO_ACCOUNT_SID=your_account_sid
supabase secrets set TWILIO_AUTH_TOKEN=your_auth_token
supabase secrets set TWILIO_PHONE_NUMBER=your_twilio_phone_number
```

## Testing Without Twilio

The application works perfectly without Twilio configuration:

1. User enters their phone number
2. OTP is generated and saved to database
3. OTP appears in browser console with message: "OTP for +91xxxxxxxxxx: 123456"
4. User enters the OTP code
5. User is authenticated successfully

This allows you to:
- Test the complete authentication flow
- Develop without SMS costs
- Share OTP codes easily during development

## Phone Number Format

- Phone numbers must be in E.164 format for Twilio: `+[country code][number]`
- The application automatically formats Indian numbers to `+91` prefix
- Example: User enters `9876543210`, system sends to `+919876543210`

## Security Notes

- OTP codes expire after 5 minutes
- Each OTP can only be used once
- Failed attempts are logged
- Phone numbers are verified before creating user accounts

## Troubleshooting

**OTP not received via SMS:**
1. Check Twilio credentials are correct
2. Verify the phone number format
3. Check Twilio account balance
4. Review Twilio logs in their dashboard
5. Ensure the phone number is verified (trial accounts)

**OTP shown in console instead of SMS:**
- This means Twilio is not configured
- Either Twilio credentials are missing or incorrect
- Check Supabase Edge Function logs for errors
- The application will continue to work with console-based OTP

## Support

For Twilio-specific issues, visit:
- Twilio Documentation: https://www.twilio.com/docs
- Twilio Support: https://support.twilio.com

For application-specific issues, check the Supabase Edge Function logs in your Supabase dashboard.
