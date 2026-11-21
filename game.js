// Shared by player, admin and test pages.
if(CFG.url.includes('YOUR-'))document.addEventListener('DOMContentLoaded',()=>document.body.innerHTML='<h2 style="padding:30px">⚠️ Edit config.js with your Supabase URL and anon key.</h2>');
const sb=supabase.createClient(CFG.url,CFG.key);
const $=s=>document.querySelector(s);
const esc=s=>String(s).replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const MED=["🥇","🥈","🥉"];
const ROUNDS=[
{k:"Historia",q:"¿Qué historia de Wattpad tiene más futuro?",h:"Mira los votos: muestran cuánto aman los lectores la historia.",c:"Engagement: los votos y comentarios dicen más que las lecturas.",o:[
 {t:"Besos en París",s:"Romance juvenil · 12 M lecturas · 400 mil votos",e:"🗼",c:["#ff7a1a","#ff2d75"]},
 {t:"El Chico de la Biblioteca",s:"Romance tierno · 8 M lecturas · 900 mil votos",e:"📚",c:["#ffa23c","#c2185b"]},
 {t:"Corazón de Fuego",s:"Drama intenso · 15 M lecturas · 300 mil votos",e:"🔥",c:["#e5173f","#3a0a18"]}]},
{k:"Actores",q:"¿Quiénes son los mejores actores?",h:"Piensa en tu historia.",c:"Casting: los actores deben parecerse a la historia y a su público.",o:[
 {t:"Estrellas de TikTok",s:"Jóvenes y famosos en redes",e:"📱"},{t:"Superestrellas de Hollywood",s:"Famosos en todo el mundo, pero caros",e:"🌟"},{t:"Actores latinos queridos",s:"Cercanos y auténticos",e:"💃"}]},
{k:"Público",q:"¿Quién es el público objetivo?",h:"¿Para quién es esta película?",c:"Público objetivo: una campaña funciona mejor cuando habla a un grupo claro.",o:[
 {t:"Adolescentes",s:"13–18 años",e:"🎧"},{t:"Jóvenes",s:"19–24 años",e:"🎓"},{t:"Adultos y familias",s:"25 años o más",e:"👨‍👩‍👧"}]},
{k:"Marketing",q:"¿Qué estrategia de marketing usan?",h:"Elige donde está tu público.",c:"Canal de marketing: usa el canal donde vive tu público (TikTok jóvenes, TV adultos).",o:[
 {t:"TikTok",s:"Videos cortos y virales",e:"🎵"},{t:"Instagram",s:"Fotos, reels e historias",e:"📸"},{t:"Publicidad tradicional",s:"Televisión, cine y carteles",e:"📺"}]},
{k:"Estreno",q:"¿Cómo es el estreno internacional?",h:"Más países = más riesgo.",c:"Lanzamiento: más países dan más ganancia posible, pero también más riesgo.",o:[
 {t:"Estreno mundial",s:"Todos los países a la vez",e:"🌍"},{t:"Latinoamérica y España primero",s:"Mismo idioma, más fácil",e:"🌎"},{t:"Festivales de cine primero",s:"Prestigio y buenas críticas",e:"🏆"}]}];
let off=0; // server clock offset so every phone shows the same countdown
async function getState(){const{data,error}=await sb.rpc('get_state');if(error)throw error;off=new Date(data.now).getTime()-Date.now();return data}
const left=g=>g&&g.closes_at?Math.max(0,Math.ceil((new Date(g.closes_at).getTime()-(Date.now()+off))/1000)):0;
const getPlayers=async()=>{const{data}=await sb.from('players').select('id,name,score').order('score',{ascending:false}).order('created_at');return data||[]};
function poster(o){return `<div class="poster" style="--a:${o.c[0]};--b:${o.c[1]}">${o.e}</div>`}
// Realtime: any change in game/players triggers fn (debounced). A 5 s poll is a safety net if the socket drops.
function live(fn){let t;const d=()=>{clearTimeout(t);t=setTimeout(fn,150)};
 sb.channel('live-'+Math.random().toString(36).slice(2)).on('postgres_changes',{event:'*',schema:'public',table:'game'},d).on('postgres_changes',{event:'*',schema:'public',table:'players'},d).subscribe();
 setInterval(fn,5000)}
