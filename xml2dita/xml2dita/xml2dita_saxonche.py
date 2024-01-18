import logging
import os
import shutil
import time

from datetime import datetime
from saxonche import *


class xml2dita:
    #  Dashed lines
    dash = '-' * 100
    temp_ditadir = ''
    dita_image_dir = ''

    def __init__(self, xmldir, prefix):
        self.xmldir = xmldir
        self.prefix = prefix
        self.script_dir = os.path.dirname(os.path.realpath(__file__))
        self.temp_dir = os.path.join(os.path.dirname(self.xmldir), 'temp')
        self.copy_source_xml_dir = os.path.join(self.temp_dir, 'xml')
        self.xslt_dir = os.path.join(os.path.dirname(os.path.realpath(__file__)), 'xslt')
        self.dita_dir = os.path.join(os.path.dirname(self.xmldir), 'dita')
        self.log_dir = os.path.join(os.path.dirname(self.xmldir), 'log')
        self.source_directory = os.path.join(self.temp_dir, 'temp_dita')

        self.make_directories()
        self.copy_source_xml()
        self.conv_xml_to_dita()

    # Convert rst files to dita
    def conv_xml_to_dita(self):
        processor = PySaxonProcessor()
        xslt_processor = processor.new_xslt30_processor()
        print("> Converting XML to DITA")
        sphinx2dita_xsl_path = os.path.join(self.xslt_dir, 'xml2dita.xsl')

        str_xdm_xml_dir = processor.make_string_value(self.copy_source_xml_dir)
        str_xdm_temp_dita_dir = processor.make_string_value(os.path.join(self.temp_dir, 'temp_dita'))
        os.mkdir(os.path.join(self.temp_dir, 'temp_dita'))

        executable = xslt_processor.compile_stylesheet(stylesheet_file=sphinx2dita_xsl_path)
        executable.set_parameter('xmlDir', str_xdm_xml_dir)
        executable.set_parameter("ditaDir", str_xdm_temp_dita_dir)

        executable.set_output_file(os.path.join(self.temp_dir, 'temp_dita'))

        executable.call_template_returning_file("main")

        # Wait for the transformation to complete
        time.sleep(3)

    # make directories dita and temp
    def make_directories(self):
        """Creates necessary directories"""
        if os.path.exists(self.dita_dir):
            shutil.rmtree(self.dita_dir)
            os.mkdir(self.dita_dir)
        else:
            os.mkdir(self.dita_dir)

        if os.path.exists(self.temp_dir):
            shutil.rmtree(self.temp_dir)
            os.mkdir(self.temp_dir)
        else:
            os.mkdir(self.temp_dir)

    # Copy xml from source directory to temp directory
    def copy_source_xml(self):
        if os.path.exists(self.xmldir):
            if os.path.exists(self.copy_source_xml_dir):
                shutil.rmtree(self.copy_source_xml_dir)
            shutil.copytree(self.xmldir, self.copy_source_xml_dir)
            print(f"> Copied source from {self.xmldir} to {self.copy_source_xml_dir}")
            print(self.dash)
