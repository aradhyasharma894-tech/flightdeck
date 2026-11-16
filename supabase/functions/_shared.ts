import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
export const admin = createClient(Deno.env.get("SUPABASE_URL")!,Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!);
export async function identity(req:Request){const h=req.headers.get("Authorization");if(!h)throw new Error("Authentication required");const token=h.replace("Bearer ","");const {data,error}=await admin.auth.getUser(token);if(error||!data.user)throw new Error("Invalid session");const {data:p}=await admin.from("profiles").select("id,display_name,role").eq("id",data.user.id).single();if(!p)throw new Error("Profile not provisioned");return {user:data.user,profile:p};}
export const cors={"Access-Control-Allow-Origin":"*","Access-Control-Allow-Headers":"authorization, x-client-info, apikey, content-type","Access-Control-Allow-Methods":"POST, OPTIONS"};
export function reply(body:any,status=200){return new Response(JSON.stringify(body),{status,headers:{...cors,"Content-Type":"application/json"}})}
