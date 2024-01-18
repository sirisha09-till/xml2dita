import argparse
import sys

from xml2dita import Xml2Dita


def main():
    # parse command line arguments
    parser = argparse.ArgumentParser(description='Generate DITA XML documentation')
    parser.add_argument('--xmldir', required=True, help='Location of XML.')
    parser.add_argument('--prefix', required=True, help='Custom id for the ditamap.')

    args = parser.parse_args()

    Xml2Dita(args.xmldir, args.prefix)


if __name__ == '__main__':
    # When called from command line
    main()
