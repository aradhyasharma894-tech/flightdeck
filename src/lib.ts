import{createClient}from"@supabase/supabase-js";
const url=import.meta.env.VITE_SUPABASE_URL as string;const key=import.meta.env.VITE_SUPABASE_ANON_KEY as string;
export const supabase=url&&key?createClient(url,key,{auth:{persistSession:true,autoRefreshToken:true,detectSessionInUrl:true}}):null;
export type Test={id:string;title:string;subject:string;duration_minutes:number;total_marks:number;description:string;is_published:boolean};
export type PublicQuestion={id:string;topic:string;prompt:string;options:string[];marks:number;sequence:number};
