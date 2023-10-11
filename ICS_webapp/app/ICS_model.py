import requests
from PIL import Image
from transformers import BlipProcessor, BlipForConditionalGeneration


def ics_model(url):
    processor = BlipProcessor.from_pretrained("Salesforce/blip-image-captioning-base")
    model = BlipForConditionalGeneration.from_pretrained("Salesforce/blip-image-captioning-base")  # .to("cuda")

    raw_image = Image.open(requests.get(url, stream=True).raw).convert('RGB')  # check user input url variable works

    # conditional image captioning, use text as the second argument
    text = "a picture of"
    # using unconditional captioning
    inputs = processor(raw_image, return_tensors="pt", )  # .to("cuda")

    out = model.generate(**inputs)
    return text + " " + processor.decode(out[0], skip_special_tokens=True)