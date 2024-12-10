/*
 * asc2kim5 - A command line utility for creating binary files suitable
 *            for use with the KIM-5 Resident Assembler
 * 
 *   https://github.com/eduardocasino/kim-5-resident-assembler
 *
 * Copyright 2024 Eduardo Casino
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the “Software”),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and topermit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */
#include <stdio.h>
#include <unistd.h>
#include <getopt.h>
#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>
#include <stdlib.h>
#define _GNU_SOURCE         // For strchrnul()
#include <string.h>
#include <libgen.h>
#include <ctype.h>
#include <errno.h>

#define BUF_SIZE 0x10000
#define LINE_SIZE 256
#define DEFAULT_LINE_INCREMENT 10
#define MAX_SYMBOL_LENGTH 6

#if __BYTE_ORDER__ == __ORDER_BIG_ENDIAN__
#define LE16(X) (uint16_t)( (( X << 8) & 0xFF00) | ((X >> 8) & 0xFF) )
#define BE16(X) (X)
#else
#define LE16(X) (X)
#define BE16(X) (uint16_t)( (( X << 8) & 0xFF00) | ((X >> 8) & 0xFF) )
#endif

typedef int (*write_fn_t)( FILE *output, const uint8_t *buffer, size_t buffer_size, void *param );

typedef struct {
    char *name;
    enum { BIN = 0, TAP, PAP } type;
    write_fn_t write_fn;
} format_t;

typedef struct {
    struct {
        bool format;
        bool line_increment;
        bool part_size;
        bool address;
        bool id;
    } flags;
    const format_t *format;
    uint16_t line_increment;
    uint16_t part_size;
    uint16_t address;
    char *ifilename;
    char *ofilename;
    uint8_t id;
} options_t;

int bin_write( FILE *file, const uint8_t* data, size_t size, void *options )
{
    int status = 0;

    for ( size_t i = 0; i < size; ++ i )
    {
        if ( 1 != fwrite( &data[i], 1, 1, file ) )
        {
            status = -1;
            break;
        }
    }

    return status;
}

int tap_write( FILE *file, const uint8_t* data, size_t size, void *options )
{
    options_t *opt = (options_t *)options;
    int status = 0;
    uint16_t start = LE16( opt->address );
    uint16_t end = LE16( opt->address + (uint16_t) size - 1 );
    uint8_t header = 0x2A;
    uint8_t tail = 0x2F;
    uint8_t endbyte = 0x04;
    uint16_t checksum = (( start >> 8 ) & 0xFF)  + (start & 0xFF) + (( end >> 8 ) & 0xFF)  + (end & 0xFF);

    if ( 1 != fwrite( &header, sizeof( header ), 1, file ) )
    {
        status = -1;
    }
    if ( 1 != fwrite( &opt->id, 1, 1, file ) )
    {
        status = -1;
    }
    if ( 1 != fwrite( &start, sizeof( start ), 1, file ) )
    {
        status = -1;
    }
    if ( 1 != fwrite( &end, sizeof( end ), 1, file ) )
    {
        status = -1;
    }

    for ( size_t i = 0; i < size; ++ i )
    {
        checksum += data[i];

        if ( 1 != fwrite( &data[i], 1, 1, file ) )
        {
            status = -1;
            break;
        }

    }

    if ( 1 != fwrite( &tail, sizeof( tail ), 1, file ) )
    {
        status = -1;
    }
    
    checksum = LE16( checksum );

    if ( 1 != fwrite( &checksum, sizeof( checksum ), 1, file ) )
    {
        status = -1;
    }

    for ( size_t i = 0; i < 2; ++ i )
    {
        if ( 1 != fwrite( &endbyte, sizeof( endbyte ), 1, file ) )
        {
            status = -1;
        }

    }

    return status;
}

int usage( char *myname )
{
    fprintf( stderr, "\nUsage: %s [-h] [-f {bin|tap} [-a <address>] [-i <num>]] [-l <num>] <input_file> <output_file>\n\n", myname );

    fputs( "Arguments:\n", stderr );
    fputs( "    input_file            Plain text file\n", stderr );
    fputs( "    output_file           Binary output file\n\n", stderr );

    fputs( "Options:\n", stderr );
    fputs( "    -h | --help                      Show this help message and exit\n", stderr );
    fputs( "    -f | --format         {bin|tap}  Specify output file format. Default is binary\n", stderr );
    fputs( "    -a | --address        <address>  Load address. Mandatory for TAP, ignored for BIN\n", stderr );
    fputs( "    -i | --id             <num>      Tape index. Ignored for BIN, default is '01'\n", stderr );
    fputs( "    -l | --line-increment <num>      Line number increment. Default is 10\n\n", stderr );

    fputs( "Outputs the space requirements for the symbol table.\n", stderr );
    
    return -1;
}

int duplicate( char *myname, char opt )
{
    fprintf( stderr, "Duplicate option: -%c\n", opt );
    return usage( myname );
}

int invalid( char *myname, const char *optname, char *optarg )
{
    fprintf( stderr, "Invalid %s: %s\n", optname, optarg );
    return usage( myname );    
}

int get_options( int argc, char **argv, options_t *options )
{
    static const format_t formats[] = {
        { "bin", BIN, bin_write },
        { "tap", TAP, tap_write },
        { NULL }
    };
    int opt, opt_index = 0;
    char *myname = basename( argv[0] );
    int retcode = -1;

    memset( options, 0, sizeof( options_t ) );

    static const struct option long_opts[] = {
        {"address",        required_argument, 0, 'a' },
        {"line-increment", required_argument, 0, 'l' },
        {"format",         required_argument, 0, 'f' },
        {"id",             required_argument, 0, 'i' },
        {"help",           no_argument,       0, 'h' },
        {0,                0 ,                0,  0  }
    };
    
    while (( opt = getopt_long( argc, argv, "a:l:f:i:h", long_opts, &opt_index)) != -1 )
    {
        switch( opt )
        {
            uint64_t number;
            char *endc;
            
            case 'a':
                if ( options->flags.address++ )
                {
                    return duplicate( myname, opt );
                }

                number = strtoul( optarg, &endc, 0 );

                if ( (number > 0xffff) || *endc )
                {
                    return invalid( myname, "address", optarg );
                }

                options->address = (uint16_t) number;
                break;

            case 'l':
                if ( options->flags.line_increment++ )
                {
                    return duplicate( myname, opt );
                }

                number = strtoul( optarg, &endc, 0 );

                if ( (number > 9999) || *endc )
                {
                    return invalid( myname, "line increment", optarg );
                }

                options->line_increment = (uint16_t) number;
                break;

            case 'f':
                if ( options->flags.format++ )
                {
                    return duplicate( myname, opt );
                }

                for ( int f = 0; formats[f].name; ++f )
                {
                    if ( !strcmp( formats[f].name, optarg ) )
                    {
                        options->format = &formats[f];
                        break;
                    }
                }

                if ( NULL == options->format )
                {
                    return invalid( myname, "format", optarg );
                }
                break;
            
            case 'i':
                if ( options->flags.id++ )
                {
                    return duplicate( myname, opt );
                }
                
                number = strtoul( optarg, &endc, 0 );

                if ( (number > 0xFE) || (number < 1) || *endc )
                {
                    return invalid( myname, "tape id", optarg );
                }

                options->id = (uint8_t) number;
                break;

            default:
                return usage( myname );
        }
    }

    if ( argc - optind < 2 )
    {
        fputs( "Input and output files are mandatory\n", stderr );
        return usage( myname );
    }

    if ( !options->flags.line_increment )
    {
        options->line_increment = DEFAULT_LINE_INCREMENT;
    }

    if ( !options->flags.format )
    {
        options->format = &formats[0];
    }
    
    if ( !options->flags.id )
    {
        options->id = 1;
    }

    if ( options->format->type != BIN && ! options->flags.address )
    {
        fprintf( stderr, "Address is mandatory for %s format\n", options->format->name );
        return usage( myname );     
    }

    options->ifilename = argv[optind++];
    options->ofilename = argv[optind++];

    return 0;
}

int output_err( char *filename )
{
    fprintf( stderr, "Error writing to the output file %s: %s\n", filename, strerror( errno ) );
    return -1;
}

uint16_t bcdenc( uint16_t num )
{
    uint16_t bcd = 0;

    bcd += ( num / 1000 ) << 12;
    bcd += ( ( num % 1000 ) / 100 ) << 8;
    bcd += ( ( num % 100 ) / 10 ) << 4;
    bcd += num % 10;

    return BE16( bcd );
}

bool is_opcode( const char *token )
{
    static const char *opcodes[] = {
		"ADC", "AND", "ASL", "BCC", "BCS", "BEQ", "BIT", "BMI",
        "BNE", "BPL", "BRK", "BVC", "BVS", "CLC", "CLD", "CLI",
        "CLV", "CMP", "CPX", "CPY", "DEC", "DEX", "DEY", "EOR",
        "INC", "INX", "INY", "JMP", "JSR", "LDA", "LDX", "LDY",
        "LSR", "NOP", "ORA", "PHA", "PHP", "PLA", "PLP", "ROL",
        "ROR", "RTI", "RTS", "SBC", "SEC", "SED", "SEI", "STA",
        "STX", "STY", "TAX", "TAY", "TSX", "TXA", "TXS", "TYA",
        NULL
    };

    for ( int opcode = 0; opcodes[opcode] != NULL; ++opcode )
    {
        if ( !strcmp( token, opcodes[opcode] ) )
        {
            return true;
        }
    }

    return false;
}

void fix_cr( char *line )
{
    char *s;
    s = strchr( line, '\r' );
    if ( s )
    {
        *(++s) = '\0';
        return;
    }
    s = strchrnul( line, '\n' );
    *(s++) = '\r';
    *s = '\0';
}

void fix_case_and_tabs( char *buffer )
{
    while ( *(buffer++) )
    {
        if ( *buffer == '\t' )
        {
            *buffer = ' ';              // Tabs are not valid separators
        }
        *buffer = toupper( *buffer );
    }
}

void print_error_indicator( const char *buffer, int pos )
{
    fprintf( stderr, "%s\n", buffer );

    for ( int p= 0; p < pos; ++p )
    {
        fputc( ' ', stderr );
    }
    fputs( "^\n", stderr );
}

// Returns:
// 0 if success
// -1 if error
//
int parse_line( size_t line, char *buffer, size_t bufsize, int *symbol_count )
{
    char *s = buffer;
    char *savep, delimiter;

    fix_cr( buffer );
    fix_case_and_tabs( buffer);

    // Advance to the first non-blank
    while ( *s == ' ' )
    {
        ++s;
    }

    // Either line was too long or has no CR
    if ( !*s )
    {
        fprintf( stderr, "Error: line %ld: No CR found.\n", line );
        return -1;
    }

    // Empty, comment or directive
    if ( (*s == ';') || (*s == '\r') || (*s == '.') || (*s == '*') )
    {
        return 0;
    }

    // First token must be an opcode or a symbol (label or constant). Either way, first char MUST be a letter
    if ( !isalpha( *s ) )
    {
        fprintf( stderr, "Error: line %ld: Expecting a (pseudo)opcode, constant or label:\n", line );
        print_error_indicator( buffer, buffer - s );
        return -1;
    }

    // Find the token end and save the delimiter char
    for ( savep = s; *savep; ++savep )
    {
        if ( (*savep == ' ') || (*savep == '=') || (*savep == '\r') )
        {
            delimiter = *savep;
            *savep = '\0';
            break;
        }
    }

    if ( strlen( s ) > MAX_SYMBOL_LENGTH )
    {
        *savep = delimiter;         // Restore delimiter
        fprintf( stderr, "Error: line %ld: Symbol length greater than %d:\n", line, MAX_SYMBOL_LENGTH );
        print_error_indicator( buffer, buffer - s );
        return -1;
    }

    if ( !is_opcode( s ) )
    {
        ++*symbol_count;
    }

    *savep = delimiter;         // Restore delimiter

    return 0;
}

int main( int argc, char **argv )
{
    static char output_buf[ BUF_SIZE ];
    static char line_buf[ LINE_SIZE + 2 ];
    options_t options;
    FILE *input, *output = NULL;
    size_t line = 0;
    uint16_t out_line_num = 0;
    int out_line_len, out_buf_len = 0;
    int symbols = 0;

    if ( get_options( argc, argv, &options ) )
    {
        return -1;
    }
    
    if ( NULL == ( input = fopen( options.ifilename, "r" ) ) )
    {
        perror( "Can't open input file" );
        return -1;
    }

    line_buf[0] = ' ';

    while ( fgets( &line_buf[1], sizeof( line_buf ) - 1, input ) > 0 )
    {
        uint16_t bcdline;

        ++line;

        if ( parse_line( line, &line_buf[1], sizeof( line_buf ) - 1, &symbols ) < 0 )
        {
            return -1;
        }

        out_line_num += options.line_increment;

        if ( out_line_num > 9999 )
        {
            fputs( "Error: line number greater than 9999. Try using a smaller line increment\n", stderr );
            return -1;
        }

        bcdline = bcdenc( out_line_num );

        out_line_len = strlen( line_buf );

        // The two extra bytes are for the final 0x1F, 0x00
        //
        if ( out_buf_len + out_line_len + sizeof( bcdline ) + 2 > 0x10000 )
        {
            fputs( "Input file too large.\n", stderr );
            return -1;
        }

        *(uint16_t *)&output_buf[out_buf_len] = bcdline;

        out_buf_len += sizeof( bcdline );

        strcpy( &output_buf[out_buf_len], line_buf );

        out_buf_len += out_line_len;
    }

    if ( !feof( input ) )
    {
        fputs( "Unexpected error reading from the input file\n", stderr );
        return -1;
    }

    fclose( input );

    // Write buffer to file
    output_buf[out_buf_len++] = 0x1F;
    output_buf[out_buf_len++] = 0x00;

    if ( NULL == ( output = fopen( options.ofilename, "wb" ) ) )
    {
        fprintf( stderr, "Can't open output file %s: %s", options.ofilename, strerror( errno ) );
        return -1;
    }

    if ( options.format->write_fn( output, output_buf, out_buf_len, &options ) )
    {
        fclose( output );
        return output_err( options.ofilename );
    }

    if ( fclose( output ) )
    {
        return output_err( options.ofilename );
    }

    printf( "Total number of symbols: %d, reserve %d (0x%4.4X) bytes for symbol table\n", symbols, symbols*8, symbols*8 );

    return 0;
}