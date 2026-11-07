# Rebuilds /mnt/project-files/ChatGPT hand-off/ from the current project files.
# Reuses sections 8 and 11-15 (LaunchWork.bat with links removed, docs text) from the previous bundle.
import re, os, shutil, sys
PF='/mnt/project-files/'
OUT=PF+'ChatGPT hand-off/'
VER=sys.argv[1]
RED=[('jakobvanness19@gmail.com','[personal email removed]'),('jakobvanness6)','[account name removed])'),
     ('prd-jvanness','[work username removed]'),('OGELPD-F9Y7XB4','PCNAME')]
def red(s):
    for a,b in RED: s=s.replace(a,b)
    return s
old=open(OUT+'Watchlog - Everything (read first).md',encoding='utf-8').read()
parts=re.split(r'\n# FILE (\d+): ([^\n]*)\n',old)
head=parts[0]
secs=[(parts[i],parts[i+1],parts[i+2]) for i in range(1,len(parts),3)]
src={'PROJECT-NOTES.md':None,'README.txt':'text','docs/Pending changes.md':None,'docs/Next Steps and Ideas.md':None,
     'templates.txt':'text','QUICK START.txt':'text','settings.example.ini':'ini','build/build.ahk':'autohotkey','build/mk_resources.py':'python'}
ahk=open(PF+'Watchlog.ahk',encoding='utf-8').read()
nlines=ahk.count('\n')+(0 if ahk.endswith('\n') else 1)
head=re.sub(r'Current program version: v\d+(?:\.\d+)*','Current program version: v'+VER,head)
head=re.sub(r'about [\d,]+ lines','about %s lines'%format(round(nlines,-2),','),head)
out=head
for n,name,body in secs:
    if name in src:
        txt=open(PF+name,encoding='utf-8-sig').read().replace('\r\n','\n').rstrip('\n')
        lang=src[name]
        body='\n'+(('```'+lang+'\n'+txt+'\n```') if lang else txt)+'\n\n\n---\n'
        if n=='15': body=body[:-6]+'\n'
    out+='\n# FILE %s: %s\n'%(n,name)+body
out=red(out)
for a,_ in RED: assert a not in out,a
open(OUT+'Watchlog - Everything (read first).md','w',encoding='utf-8').write(out)
assert not any(a in ahk for a,_ in RED)
shutil.copy(PF+'Watchlog.ahk',OUT+'Watchlog.ahk')
# parts, about 50 KB each, split at a blank line before a top-level line
pd=OUT+'Watchlog.ahk in parts/'
for f in os.listdir(pd): os.remove(pd+f)
L=ahk.split('\n')
if L[-1]=='': L=L[:-1]
k=max(1,round(len(ahk.encode())/50000))
cuts=[0]; size=len(ahk)/k
pos=0; acc=0
for i,l in enumerate(L):
    acc+=len(l)+1
    if len(cuts)<k and acc>=size*len(cuts) and l.strip()=='' and i+1<len(L) and L[i+1][:1] not in ('',' ','\t'):
        cuts.append(i+1)
cuts.append(len(L)); k=len(cuts)-1
for j in range(k):
    a,b=cuts[j],cuts[j+1]
    hdr='; ===== Watchlog.ahk PART %d of %d (lines %d-%d of %d). Delete this first line from each part, then join all %d in order to get the full file. =====\n'%(j+1,k,a+1,b,len(L),k)
    open(pd+'Watchlog.ahk part %d of %d.txt'%(j+1,k),'w',encoding='utf-8').write(hdr+'\n'.join(L[a:b])+'\n')
# check the join
joined=''.join(open(pd+'Watchlog.ahk part %d of %d.txt'%(j+1,k),encoding='utf-8').read().split('\n',1)[1] for j in range(k))
assert joined=='\n'.join(L)+'\n'
h=open(OUT+'HOW TO USE THIS WITH CHATGPT.txt',encoding='utf-8').read()
h=re.sub(r'\(v[\d.]+, about [\d,]+ lines\)','(v%s, about %s lines)'%(VER,format(round(nlines,-2),',')),h)
h=re.sub(r'the \d+\s+parts one at a time','the %d parts one at a time'%k,h)
h=re.sub(r'in \d+ parts','in %d parts'%k,h)
open(OUT+'HOW TO USE THIS WITH CHATGPT.txt','w',encoding='utf-8').write(h)
print('parts',k,'lines',len(L))
