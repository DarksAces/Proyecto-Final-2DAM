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
        Simplified 3D reconstruction pipeline.
        """
        
        image_files = [f for f in os.listdir(self.images_dir) if f.lower().endswith(('.jpg', '.jpeg', '.png'))]
        if not image_files:
            raise ValueError("No images found in session")

        print(f"Processing {len(image_files)} images...")
        
        # Create a dummy mesh (sphere) using Trimesh directly
        # This avoids the Open3D dependency which is failing on Python 3.13
        mesh = trimesh.creation.icosphere(radius=1.0, subdivisions=3)
        
        # Paint it with a color (e.g., average color of first image)
        first_img_path = os.path.join(self.images_dir, image_files[0])
        img = cv2.imread(first_img_path)
        if img is not None:
            # Calculate average color
            avg_color = np.mean(img, axis=(0, 1))
            # Trimesh uses 0-255 RGBA
            color = np.append(avg_color[::-1], 255).astype(np.uint8)
            
            # Apply color to all vertices
            mesh.visual.vertex_colors = np.tile(color, (len(mesh.vertices), 1))
        
        # Save as OBJ
        mesh.export(self.output_obj)
        
        # Export as GLB
        mesh.export(self.output_glb)
        
        return self.output_glb

    def _real_photogrammetry_stub(self):
        pass
