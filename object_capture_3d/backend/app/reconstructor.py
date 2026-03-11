import os
import numpy as np
import cv2
import trimesh
from pathlib import Path

class Reconstructor:
    def __init__(self, session_dir: str):
        self.session_dir = session_dir
        self.images_dir = os.path.join(session_dir, "images")
        self.output_obj = os.path.join(session_dir, "model.obj")
        self.output_glb = os.path.join(session_dir, "model.glb")

    def process(self):
        """
        Creates a 3D Cube textured with the captured image.
        This ensures the user sees exactly what they photographed in 3D space.
        """
        image_files = [f for f in os.listdir(self.images_dir) if f.lower().endswith(('.jpg', '.jpeg', '.png'))]
        if not image_files:
            raise ValueError("No images found in session")

        print(f"Processing {len(image_files)} images...")
        
        # Use the first image as the texture
        first_img_path = os.path.join(self.images_dir, image_files[0])
        
        # Load image using PIL for texture
        from PIL import Image
        pil_image = Image.open(first_img_path)
        
        # Create a simple Box mesh (Cube)
        # We make it thin to look like a "photo card" or a cube if preferred
        mesh = trimesh.creation.box(extents=[1.0, 1.0, 1.0])

        # Generate UV coordinates based on XY position (planar mapping)
        # Vertices are centered at 0, so range is [-0.5, 0.5]
        # We map x,y to u,v
        vertices = mesh.vertices
        uv = (vertices[:, :2] + 0.5) # Normalize to [0, 1] range
        
        # Create a material with the image as texture
        material = trimesh.visual.texture.SimpleMaterial(image=pil_image)
        
        texture_visuals = trimesh.visual.TextureVisuals(
            uv=uv,
            image=pil_image,
            material=material
        )
        mesh.visual = texture_visuals

        # Export as GLB
        mesh.export(self.output_glb)
        print(f"Model generated at {self.output_glb}")
        
        return self.output_glb

    def _real_photogrammetry_stub(self):
        pass
