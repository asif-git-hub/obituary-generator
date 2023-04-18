'''
request
{
  "id": "ec876a8c-d37a4fe2-b7a1-7fbd2d23046a",
  "name": "Test Tester",
  "birth_date": "04/12/2023, 12:00 AM",
  "death_date": "2023-04-16T04:51:05.816Z",
  "obituary": "Test Tester, born on April 12, 2023, at 12:00 a.m., passed away on April 16, at 4:51 p.m. She was a dedicated tester who always put the needs of her team first. Test Tester will be deeply missed, but her legacy will live on through the countless tests she conducted.",
  "image_url": "http://res.cloudinary.com/du5wbd7af/image/upload/v1681624029/i0dvv2et87hntuqrmgqg.png",
  "mp3_url": "http://res.cloudinary.com/du5wbd7af/raw/upload/v1681624781/c3rtcmwkgjygud6votgq.mp3"
}
'''
# STEP 3
def lambda_handler(event, context):
    image_url = event["image_url"].split("image/upload/")
    new_image_url = f"{image_url[0]}image/upload/e_art:zorro/{image_url[1]}"

    return {
        "id": event["id"],
        "name": event["name"],
        "birth_date": event["birth_date"],
        "death_date": event["death_date"],
        "obituary": event["obituary"],
        "image_url": new_image_url,
        "mp3_url": event["mp3_url"]
    }
