import torch
import pandas as pd
import coremltools as ct
from PIL import Image
from torchvision import transforms, models
from coremltools.models.neural_network.quantization_utils import quantize_weights

labels = list(pd.read_csv("labels.csv", header=None)[0])
print("Labels count: ", len(labels))

# Download the model
base_model = models.mobilenet_v2(pretrained=True).eval()

class ProbModel(torch.nn.Module):
    def __init__(self):
        super().__init__()
        self.base_model = base_model

    def forward(self, image):
        logits = self.base_model(image)
        return torch.nn.functional.softmax(logits, dim=1)

model = ProbModel()

# Trace the model with random data
example_input = torch.rand(1, 3, 224, 224)
traced_model = torch.jit.trace(model, example_input)
out = traced_model(example_input)
print(out.shape)

# Convert the model
scale = 1/(0.226*255.0)
bias = [- 0.485/(0.229) , - 0.456/(0.224), - 0.406/(0.225)]

model = ct.convert(
    traced_model,
    inputs=[ct.ImageType(
        name="image",
        shape=ct.Shape(shape=(1, 3, ct.RangeDim(), ct.RangeDim())),
        scale=scale,
        bias=bias)],
    classifier_config=ct.ClassifierConfig(labels)
)

out = quantize_weights(model, nbits=16)
if isinstance(out, ct.models.model.MLModel):
    # When the export is done on OSX, return is an mlmodel.
    spec = out.get_spec()
else:
    # When the export is done on Linux, the return is a spec.
    spec = out

model_name = 'MobilenetV2Custom.mlmodel'
ct.utils.rename_feature(spec, spec.description.output[0].name, 'classLabelProbs')
ct.utils.save_spec(spec, model_name)

# Make a prediction using Core ML.
model = ct.models.MLModel(model_name)
out_dict = model.predict({'image': transforms.ToPILImage()(example_input[0])})
print(out_dict.keys())

import pdb; pdb.set_trace()
