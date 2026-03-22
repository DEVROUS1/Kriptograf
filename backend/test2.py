import asyncio, httpx, urllib.parse
async def r():
  url = f'https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=tr&dt=t&q={urllib.parse.quote("Bitcoin up")}'
  c=await httpx.AsyncClient().get(url)
  print(c.json())
asyncio.run(r())
