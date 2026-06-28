
document.addEventListener('DOMContentLoaded',()=>{
const sidebar=document.getElementById('sidebar');
const btn=document.getElementById('mobile-menu-btn');
const close=document.getElementById('close-sidebar-btn');
const headerLogo=document.getElementById('header-logo');
if(!sidebar) return;

function apply(){
 const collapsed=localStorage.getItem('sidebar-collapsed')==='true';
 if(window.innerWidth>=1024){
   sidebar.classList.remove('-translate-x-full');
   sidebar.style.width=collapsed?'0px':'256px';
   sidebar.querySelectorAll('.nav-text,.logo-text').forEach(e=>e.style.display=collapsed?'none':'');
   if(headerLogo) headerLogo.style.display=collapsed?'flex':'none';
 }
}
apply();

btn?.addEventListener('click',()=>{
 if(window.innerWidth>=1024){
   const c=localStorage.getItem('sidebar-collapsed')==='true';
   localStorage.setItem('sidebar-collapsed',(!c).toString());
   apply();
 } else {
   sidebar.classList.toggle('-translate-x-full');
   if(headerLogo) headerLogo.style.display=sidebar.classList.contains('-translate-x-full')?'flex':'none';
 }
});

close?.addEventListener('click',()=>{
  sidebar.classList.add('-translate-x-full');
  if(headerLogo) headerLogo.style.display='flex';
});
window.addEventListener('resize',apply);
});
