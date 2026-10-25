from PIL import Image, ImageDraw
S=1024
TEAL=(14,116,110,255); DARK=(10,70,66,255); WHITE=(255,255,255,255); LINE=(150,170,170,255); AMBER=(245,166,35,255)
def icon(size):
    img=Image.new("RGBA",(S,S),(0,0,0,0)); d=ImageDraw.Draw(img)
    small=size<=24
    m=0 if small else 40
    d.rounded_rectangle([m,m,S-m,S-m],radius=150 if small else 200,fill=TEAL)
    # page
    px0,py0,px1,py1=(200,110,824,914) if small else (250,170,774,860)
    fold=200 if small else 150
    d.polygon([(px0,py0),(px1-fold,py0),(px1,py0+fold),(px1,py1),(px0,py1)],fill=WHITE)
    d.polygon([(px1-fold,py0),(px1-fold,py0+fold),(px1,py0+fold)],fill=(200,215,214,255))
    lw=90 if small else 46
    ys=[520,720] if small else [400,500,600,700]
    for i,y in enumerate(ys):
        x1=px1-100 if i<len(ys)-1 else px0+300
        d.rounded_rectangle([px0+80,y-lw//2,x1,y+lw//2],radius=lw//2,fill=LINE if not small else (110,135,135,255))
    if not small:
        # eye at top left of page
        cx,cy=px0+175,290
        d.ellipse([cx-95,cy-60,cx+95,cy+60],fill=DARK)
        d.ellipse([cx-42,cy-42,cx+42,cy+42],fill=AMBER)
        d.ellipse([cx-16,cy-16,cx+16,cy+16],fill=DARK)
    else:
        d.ellipse([px0+90,220,px0+330,380],fill=AMBER)
    return img.resize((size,size),Image.LANCZOS)
sizes=[16,20,24,32,40,48,64,128,256]
imgs=[icon(s) for s in sizes]
imgs[-1].save("LogTemplates.ico",format="ICO",sizes=[(s,s) for s in sizes],append_images=imgs[:-1])
# preview sheet on light and dark
sheet=Image.new("RGBA",(900,300),(240,240,240,255))
x=20
for s,im in zip(sizes,imgs):
    if s in (16,24,32,48,128,256):
        sheet.alpha_composite(im,(x,20)); x+=s+20
dark=Image.new("RGBA",(900,140),(32,32,32,255))
x=20
for s,im in zip(sizes,imgs):
    if s in (16,24,32,48,64,128):
        dark.alpha_composite(im,(x,6)); x+=s+20
out=Image.new("RGBA",(900,440)); out.paste(sheet,(0,0)); out.paste(dark,(0,300))
# zoomed 16 and 32
z=Image.new("RGBA",(260,130),(240,240,240,255))
z.alpha_composite(imgs[0].resize((112,112),Image.NEAREST),(5,9)); z.alpha_composite(imgs[3].resize((112,112),Image.NEAREST),(135,9))
out.paste(z,(620,20))
out.save("preview.png")
